require 'uuidtools'

module Smsim

  class Gateway
    attr_reader :username

    def initialize(username, password)
      @username = username
      @password = password
    end

    # send +text+ string to the phones specified in +phones+ array
    # @returns unique message id string. you must save this id if you want to receive delivery notifications via push/pull
    def send(text, phones, options = {})
      options = {:reply_to_number => "0545290862"}.update(options)
      message_id = UUIDTools::UUID.timestamp_create.to_str
      xml = XmlRequestBuilder.build_send_sms(text, phones, options.update(:username => @username, :password => @password, :customer_message_id => message_id))
      response = HttpExecutor.send_sms(xml)
      raise GatewayError.new(response.status, "Sms send failed: #{response.description}") unless self.send_response_status_ok?(response.status)
      message_id
    end
    
    private
    def send_response_status_ok?(status)
      status == 1
    end

  end

end

