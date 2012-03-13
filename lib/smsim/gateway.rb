require 'uuidtools'

module Smsim

  class Gateway
    extend GatewayUrls
    # Create new gateway with given +username+ and +password+
    # +options+ hash can have the following keys:
    #  * delivery_notification_url - url to which delivery notification will be sent
    #  * reply_to_number - to which number sms receiver will reply
    # These keys will be used when sending sms messages
    def initialize(username, password, options = {})
      @options = options
      @options[:username] = username
      @options[:password] = password
      raise ArgumentError.new("Username must be present") if username.blank?
      raise ArgumentError.new("Password must be present") if password.blank?
    end

    def username
      @options[:username]
    end

    # send +text+ string to the phones specified in +phones+ array
    # +options+ hash can have the following keys:
    #  * delivery_notification_url - url to which delivery notification will be sent
    #  * reply_to_number - to which number sms receiver will reply
    # Returns unique message id string. Uou must save this id if you want to receive delivery notifications via push/pull
    def send_sms(text, phones, options = {})
      options = options.update(@options)
      options[:message_id] = self.class.generate_message_id
      xml = XmlRequestBuilder.build_send_sms(text, phones, options)
      response = HttpExecutor.send_sms(xml)
      raise Smsim::Errors::GatewayError.new(response.status, "Sms send failed: #{response.description}") unless self.class.send_response_status_ok?(response.status)
      options[:message_id]
    end

    def self.generate_message_id
      UUIDTools::UUID.timestamp_create.to_str
    end

    def self.send_response_status_ok?(status)
      status == 1
    end

  end

end

