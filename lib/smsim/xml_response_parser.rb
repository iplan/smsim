require 'ostruct'
require 'nokogiri'

module Smsim
  
  class XmlResponseParser

    def self.parse_sms_send_response(httparty_response)
      xml = httparty_response.parsed_response
      begin
        doc = ::Nokogiri::XML(xml)
        OpenStruct.new({
          :status => Integer(doc.css('Result Status').text),
          :number_of_recipients => Integer(doc.css('Result NumberOfRecipients').text),
          :description => doc.css('Result Description').text
        })
      rescue Exception => e
        raise Smsim::Errors::XmlResponseError.new(100, e.message)
      end
    end

  end

end

