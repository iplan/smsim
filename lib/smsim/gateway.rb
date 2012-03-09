module Smsim

  class Gateway
    attr_reader :username

    def initialize(username, password)
      @username = username
      @password = password
    end

    # send +text+ string to the phones specified in +phones+ array
    def send(text, phones, options = {})
      options = {:reply_to_number => "0502813182"}.update(options)
      xml = XmlRequestBuilder.build_send_sms(text, phones, options.update(:username => @username, :password => @password))
      response = HttpExecutor.send_sms(xml)
      raise GatewayError.new(response.status, "Sms send failed: #{response.description}") if response.error?
      true
    end

  end

end

