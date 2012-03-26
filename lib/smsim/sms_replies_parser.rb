require 'nokogiri'

module Smsim
  class SmsRepliesParser


    # params will look something like the following:
    # { "IncomingXML" => "<IncomingData>
    #                      <PhoneNumber>0501111111</PhoneNumber>
    #                      <Keyword>Hello</Keyword>
    #                      <Message>Hello Word</Message>
    #                      <Network>052</Network>
    #                      <ShortCode>5454</ShortCode>
    #                      <CustomerID>12</CustomerID>
    #                      <ProjectID>123</ProjectID>
    #                      <ApplicationID>12321</ApplicationID>
    #                    </IncomingData>" }
    # PhoneNumber - the number of person who replied to sms
    # Message - text of the message
    # ShortCode - number to which reply was sent (0529992090)
    def self.http_push(params)
      ['IncomingXML'].each do |p|
        raise Smsim::Errors::GatewayError.new(601, "Missing http parameter #{p}. Parameters were: #{params.inspect}") if params[p].blank?
      end

      begin
        doc = ::Nokogiri::XML(params['IncomingXML'])
        parse_reply_values_hash(
          :phone => doc.at_css('IncomingData PhoneNumber').text,
          :text => doc.at_css('IncomingData Message').text,
          :reply_to_phone => doc.at_css('IncomingData ShortCode').text
        )
      rescue Exception => e
        raise Smsim::Errors::GatewayError.new(602, e.message)
      end
    end

    # This method receives sms reply +values+ Hash and tries to type cast it's values
    # @raises Smsim::Errors::GatewayError when values hash is missing attributes or when one of attributes fails to be type casted
    #
    # Method returns object with the following attributes:
    # * +phone+ - the phone that sent the sms (from which sms reply was received)
    # * +text+ - contents of the message that were received
    # * +reply_to_phone+ - the phone to sms which reply was sent (gateway phone number)
    # * +received_at+ - when the sms was received (as reported by gateway server)
    # * +message_id+ - uniq message id generated from phone,reply_to_phone and received_at timestamp
    def self.parse_reply_values_hash(values)
      [:phone, :text, :reply_to_phone].each do |key|
        raise Smsim::Errors::GatewayError.new(601, "Missing sms reply values key #{key}. Values were: #{values.inspect}") if values[key].blank?
      end

      values[:phone] = PhoneNumberUtils.ensure_country_code(values[:phone])
      values[:reply_to_phone] = PhoneNumberUtils.ensure_country_code(values[:reply_to_phone])

      if values[:received_at].is_a?(String)
        begin
          values[:received_at] = DateTime.strptime(values[:received_at], '%d/%m/%Y %H:%M:%S')
        rescue Exception => e
          raise Smsim::Errors::GatewayError.new(603, "NotificationDate could not be converted to date. NotificationDate was: #{values[:received_at]}")
        end
      else
        values[:received_at] = Time.now
      end
      values[:message_id] = generate_reply_message_id(values[:phone], values[:reply_to_phone], values[:received_at])
      OpenStruct.new(values)
    end

    def self.generate_reply_message_id(from_phone, reply_to_phone, received_at)
      p1 = from_phone.to_i(36).to_s(36)
      p2 = reply_to_phone.to_i(36).to_s(36)
      p3 = received_at.to_i.to_s(36)
      "#{p1}-#{p2}-#{p3}"
    end

  end
end
