require 'httparty'

module Smsim

  class HttpExecutor
    include ::HTTParty
    base_uri 'http://api.smsim.co.il'
    @@send_sms_uri = "#{base_uri}/SendMessageXml.ashx"
    def self.send_sms_uri; @@send_sms_uri; end

    #base_uri 'http://localhost:3000/en-US/front'

    def self.send_sms(xml)
      #self.post('/contact', :body => {:InforuXML => xml})
      puts "#{xml}"
      response = do_post(@@send_sms_uri, :body => {:InforuXML => xml})
      XmlResponse.new(response)
    end

    def self.do_post(path, options={})
      response = self.post(path, options)
      parse_response(response)
    end

    def self.do_get(path, options={})
      response = self.get(path, options)
      parse_response(response)
    end

    def self.parse_response(response)
      case response.code
        when 200 #all good, return response for further parsing
          response
        when 400
          raise HttpError.new(400, "Bad request to #{response.request.last_uri} \n#{response.parsed_response}")
        when 401
          raise HttpError.new(401, "Unauthorized: #{response.request.last_uri} \n#{response.parsed_response}")
        when 403
          raise HttpError.new(401, "Forbidden: #{response.request.last_uri} \n#{response.parsed_response}")
        when 404
          raise HttpError.new(404, "Url not found #{response.request.last_uri} \n#{response.parsed_response}")
        when 500...600
          raise HttpError.new(response.code, "Error on server at #{response.request.last_uri} \n#{response.parsed_response}")
      end
    end

  end

end
