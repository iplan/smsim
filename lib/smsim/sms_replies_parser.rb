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
          :replied_to => doc.at_css('IncomingData ShortCode').text
        )
      rescue Exception => e
        raise Smsim::Errors::GatewayError.new(602, e.message)
      end
    end

    def self.parse_reply_values_hash(values)
      if values[:received_at].is_a?(String)
        begin
          values[:received_at] = DateTime.strptime(values[:received_at], '%d/%m/%Y %H:%M:%S')
        rescue Exception => e
          raise Smsim::Errors::GatewayError.new(603, "NotificationDate could not be converted to date. NotificationDate was: #{values[:received_at]}")
        end
      else
        values[:received_at] = Time.now
      end
      OpenStruct.new(values)
    end

  end
end
