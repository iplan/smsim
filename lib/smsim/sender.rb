require 'httparty'
require 'logging'

module Smsim

  # this class sends smses and parses repsones
  class Sender
    include ::HTTParty
    attr_reader :logger

    # Create new sms sender with given +options+ with the following keys:
    #  * +username+ - gateway username
    #  * +password+ - gateway password
    #  * +delivery_notification_url+ - url to which delivery notification will be sent
    #  * +reply_to_number+ - to which number sms receiver will reply
    # These keys will be used when sending sms messages
    def initialize(options)
      raise ArgumentError.new("HTTP post url is missing") if options[:http_post_url].blank?
      raise ArgumentError.new("Username and password must be present") if options[:username].blank? || options[:password].blank?
      raise ArgumentError.new("Username and password must be present") if options[:username].blank? || options[:password].blank?
      raise ArgumentError.new("Reply to number must be cellular phone with 972 country code") if options[:reply_to_number].present? && !PhoneNumberUtils.valid_cellular_phone?(options[:reply_to_number])
      @options = options
      @logger = Logging.logger[self.class]
    end

    def send_sms(message_text, phones)
      raise ArgumentError.new("Text must be at least 1 character long") if message_text.blank?
      raise ArgumentError.new("No phones were given") if phones.blank?
      phones = [phones] unless phones.is_a?(Array)
      # check that phones are in valid cellular format
      for p in phones
        raise ArgumentError.new("Phone number '#{p}' must be cellular phone with 972 country code") unless PhoneNumberUtils.valid_cellular_phone?(p)
      end
      #raise ArgumentError.new("Max phones number is 100") if phones.count > 100

      message_id = generate_message_id
      xml = build_send_sms_xml(message_text, phones, message_id)
      logger.debug "#send_sms - making post to #{@options[:http_post_url]} with xml: \n #{xml}"
      response = self.class.post(@options[:http_post_url], :body => {:InforuXML => xml})
      logger.debug "#send_sms - got http response: code=#{response.code}; body=\n#{response.parsed_response}"
      verify_http_response_code(response) # error will be raised if response code is bad
      response = parse_response_xml(response)
      response.message_id = message_id
      logger.debug "#send_sms - parsed response: #{response.inspect}"
      if response.status != 1
        raise Smsim::Errors::GatewayError.new(Smsim::Errors::GatewayError.map_send_sms_xml_response_status(response.status), "Sms send failed (status #{response.status}): #{response.description}")
      end
      response
    end

    def build_send_sms_xml(message_text, phones, message_id)
      # enhance it with gateway_user parameter
      #if options[:delivery_notification_url].present?
      #  prefix = options[:delivery_notification_url].include?('?') ? '&' : '?'
      #  options[:delivery_notification_url] << "#{prefix}gateway_user=#{options[:username]}"
      #end

      xml = Builder::XmlMarkup.new(:indent => 2)
      xml.instruct!
      xml.Inforu do |root|
        root.User do |user|
          user.Username @options[:username]
          user.Password @options[:password]
        end
        root.Content(:Type => 'sms') do |content|
          content.Message message_text
        end
        root.Recipients do |recipients|
          recipients.PhoneNumber phones.join(';')
        end
        root.Settings do |settings|
          settings.SenderNumber @options[:reply_to_number]
          settings.CustomerMessageId message_id
          settings.DeliveryNotificationUrl @options[:delivery_notification_url] if @options[:delivery_notification_url].present?
        end
      end
    end

    def verify_http_response_code(response)
      case response.code
        when 200
          #all good do not raise anything
          true
        when 400
          raise Smsim::Errors::GatewayError.new(400, "Bad request to #{response.request.last_uri} \n#{response.parsed_response}")
        when 401
          raise Smsim::Errors::GatewayError.new(401, "Unauthorized: #{response.request.last_uri} \n#{response.parsed_response}")
        when 403
          raise Smsim::Errors::GatewayError.new(403, "Forbidden: #{response.request.last_uri} \n#{response.parsed_response}")
        when 404
          raise Smsim::Errors::GatewayError.new(404, "Url not found #{response.request.last_uri} \n#{response.parsed_response}")
        when 500...600
          raise Smsim::Errors::GatewayError.new(450, "Error on server at #{response.request.last_uri} \n#{response.parsed_response}")
      end
    end

    def parse_response_xml(httparty_response)
      xml = httparty_response.parsed_response
      begin
        doc = ::Nokogiri::XML(xml)
        OpenStruct.new({
          :status => Integer(doc.at_css('Result Status').text),
          :number_of_recipients => Integer(doc.at_css('Result NumberOfRecipients').text),
          :description => doc.at_css('Result Description').text,
        })
      rescue Exception => e
        raise Smsim::Errors::GatewayError.new(250, e.message)
      end
    end

    def generate_message_id
      UUIDTools::UUID.timestamp_create.to_str
    end

  end

end