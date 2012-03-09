module Smsim
  class XmlResponse
    attr_reader :status, :description, :number_of_recipients

    def initialize(httparty_response)
      xml = httparty_response.parsed_response
      begin
        doc = Nokogiri::XML(xml)
        @description = doc.css('Result Description').text
        @status = Integer(doc.css('Result Status').text)
        @number_of_recipients = Integer(doc.css('Result NumberOfRecipients').text)
      rescue Exception => e
        raise GatewayError.new(100, e.message)
      end
    end

    def error?
      status != 1
    end

    def success?
      status == 1
    end
  end
end

