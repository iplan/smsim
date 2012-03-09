require 'ostruct'
require 'httparty'

module Smsim

  class HttpExecutor
    include ::HTTParty

    @@urls = OpenStruct.new({
      :send_sms => "http://api.smsim.co.il/SendMessageXml.ashx"
    })
    def self.urls; @@urls; end

    def self.send_sms(xml)
      response = self.post(@@urls.send_sms, :body => {:InforuXML => xml})
      verify_response_code(response) # error will be raised if response code is bad
      XmlResponseParser.parse_sms_send_response(response)
    end

    def self.verify_response_code(response)
      case response.code
        when 200
          #all good do not raise anything
          true
        when 400
          raise Smsim::Errors::HttpResponseError.new(400, "Bad request to #{response.request.last_uri} \n#{response.parsed_response}")
        when 401
          raise Smsim::Errors::HttpResponseError.new(401, "Unauthorized: #{response.request.last_uri} \n#{response.parsed_response}")
        when 403
          raise Smsim::Errors::HttpResponseError.new(401, "Forbidden: #{response.request.last_uri} \n#{response.parsed_response}")
        when 404
          raise Smsim::Errors::HttpResponseError.new(404, "Url not found #{response.request.last_uri} \n#{response.parsed_response}")
        when 500...600
          raise Smsim::Errors::HttpResponseError.new(response.code, "Error on server at #{response.request.last_uri} \n#{response.parsed_response}")
      end
    end

  end

end
