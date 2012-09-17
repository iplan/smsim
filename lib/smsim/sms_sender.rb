require 'httparty'
require 'logging'

module Smsim

  # this class sends smses and parses repsones
  class SmsSender
    include ::HTTParty
    attr_reader :logger, :gateway

    # Create new sms sender with given +gateway+
    def initialize(gateway)
      @gateway = gateway
      @logger = Logging.logger[self.class]
    end

    def api_send_sms_url
      @gateway.inforu_urls[:send_sms]
    end

    def send_sms(message_text, phones, options = {})
      raise ArgumentError.new("Text must be at least 1 character long") if message_text.blank?
      raise ArgumentError.new("No phones were given") if phones.blank?
      raise ArgumentError.new("Either :sender_name or :sender_number attribute required") if options[:sender_name].blank? && options[:sender_number].blank?
      raise ArgumentError.new("Reply to number must be cellular or land line phone with 972 country code, was: #{options[:sender_number]}") if options[:sender_number].present? && !PhoneNumberUtils.valid_sender_number?(options[:sender_number])
      raise ArgumentError.new("Sender name must be max 11 latin chars") if options[:sender_name].present? && !(options[:sender_name] =~ /^[a-z]{3,11}$/i)

      phones = [phones] unless phones.is_a?(Array)
      # check that phones are in valid cellular format
      for p in phones
        raise ArgumentError.new("Phone number '#{p}' must be cellular phone with 972 country code") unless PhoneNumberUtils.valid_cellular_phone?(p)
      end
      #raise ArgumentError.new("Max phones number is 100") if phones.count > 100

      message_id = generate_message_id
      xml = build_send_sms_xml(message_text, phones, message_id, options)
      logger.debug "#send_sms - making post to #{api_send_sms_url} with xml: \n #{xml}"
      http_response = self.class.post(api_send_sms_url, :body => {:InforuXML => xml})
      logger.debug "#send_sms - got http response: code=#{http_response.code}; body=\n#{http_response.parsed_response}"
      verify_http_response_code(http_response) # error will be raised if response code is bad
      xml = http_response.parsed_response
      response = parse_response_xml(http_response)
      response.message_id = message_id
      response.sender_name = options[:sender_name]
      response.sender_number = options[:sender_number]
      logger.debug "#send_sms - parsed response: #{response.inspect}"
      if response.status != 1
        raise Smsim::GatewayError.new(Smsim::GatewayError.map_send_sms_xml_response_status(response.status), "Sms send failed (status #{response.status}): #{response.description}", :xml_response => xml, :parsed_response => response)
      end
      response
    end

    def build_send_sms_xml(message_text, phones, message_id, options = {})
      xml = Builder::XmlMarkup.new(:indent => 2)
      xml.instruct!
      xml.Inforu do |root|
        root.User do |user|
          user.Username @gateway.username
          user.Password @gateway.password
        end
        root.Content(:Type => 'sms') do |content|
          content.Message message_text
        end
        root.Recipients do |recipients|
          recipients.PhoneNumber phones.join(';')
        end
        root.Settings do |settings|
          sender_name = options[:sender_name]
          settings.SenderName sender_name if sender_name.present?
          sender_number = options[:sender_number]
          settings.SenderNumber PhoneNumberUtils.without_country_code(sender_number) if sender_number.present?
          settings.CustomerMessageId message_id
          settings.DeliveryNotificationUrl options[:delivery_notification_url] if options[:delivery_notification_url].present?
        end
      end
    end

    def verify_http_response_code(http_response)
      case http_response.code
        when 200
          #all good do not raise anything
          true
        when 400
          raise Smsim::GatewayError.new(400, "Bad request to #{http_response.request.last_uri} \n#{http_response.parsed_response}", :http_response => http_response)
        when 401
          raise Smsim::GatewayError.new(401, "Unauthorized: #{http_response.request.last_uri} \n#{http_response.parsed_response}", :http_response => http_response)
        when 403
          raise Smsim::GatewayError.new(403, "Forbidden: #{http_response.request.last_uri} \n#{http_response.parsed_response}", :http_response => http_response)
        when 404
          raise Smsim::GatewayError.new(404, "Url not found #{http_response.request.last_uri} \n#{http_response.parsed_response}", :http_response => http_response)
        when 500...600
          raise Smsim::GatewayError.new(450, "Error on server at #{http_response.request.last_uri} \n#{http_response.parsed_response}", :http_response => http_response)
      end
    end

    def parse_response_xml(xml)
      begin
        doc = ::Nokogiri::XML(xml)
        OpenStruct.new({
          :status => Integer(doc.at_css('Result Status').text),
          :number_of_recipients => Integer(doc.at_css('Result NumberOfRecipients').text),
          :description => doc.at_css('Result Description').text,
        })
      rescue Exception => e
        raise Smsim::GatewayError.new(250, e.message)
      end
    end

    def generate_message_id
      UUIDTools::UUID.timestamp_create.to_str
    end

  end

end