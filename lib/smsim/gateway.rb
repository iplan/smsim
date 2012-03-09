require 'uuidtools'

module Smsim

  class Gateway
    attr_reader :username

    def initialize(username, password)
      @username = username
      @password = password
    end

    # send +text+ string to the phones specified in +phones+ array
    # +options+ array can hav the following keys:
    #  * delivery_notification_url - url to which delivery notification will be sent
    #  * reply_to_number - to which number sms receiver will reply
    # @returns unique message id string. you must save this id if you want to receive delivery notifications via push/pull
    def send(text, phones, options = {})
      options = {:reply_to_number => "0545290862"}.update(options)
      message_id = self.class.generate_message_id
      xml = XmlRequestBuilder.build_send_sms(text, phones, options.update(:username => @username, :password => @password, :customer_message_id => message_id))
      response = HttpExecutor.send_sms(xml)
      raise Smsim::Errors::GatewayError.new(response.status, "Sms send failed: #{response.description}") unless self.class.send_response_status_ok?(response.status)
      message_id
    end

    def self.generate_message_id
      UUIDTools::UUID.timestamp_create.to_str
    end

    def self.send_response_status_ok?(status)
      status == 1
    end

  end

end

