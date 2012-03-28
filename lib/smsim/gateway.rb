require 'uuidtools'

module Smsim

  class Gateway
    attr_reader :username, :options

    # Create new gateway with given +username+ and +password+
    # +options+ hash can have the following keys:
    #  * delivery_notification_url - url to which delivery notification will be sent
    #  * reply_to_number - to which number sms receiver will reply
    # These keys will be used when sending sms messages
    def initialize(username, password, options = {})
      @options = options
      @urls = Smsim.config.urls.merge(@options.delete(:urls) || {})
      @username = username
      @password = password
      raise ArgumentError.new("Username and password must be present") if @username.blank? || @password.blank?

      @sms_sender = Sender.new(options.merge(:username => username, :password => password, :http_post_url => @urls[:send_sms]))
      @report_puller = ReportPuller.new(options.merge(:username => username, :password => password, :wsdl_url => @urls[:delivery_notifications_and_sms_replies_report_pull]))
    end

    # send +text+ string to the phones specified in +phones+ array
    # Returns response OpenStruct that contains:
    #  * +message_id+ - message id string. You must save this id if you want to receive delivery notifications via push/pull
    #  * +status+ - gateway status of sms send
    #  * +number_of_recipients+ - number of recipients the message was sent to
    def send_sms(text, phones)
      @sms_sender.send_sms(text, phones)
    end

    def on_delivery_notification_http_push(params)
      Smsim::DeliveryNotificationsParser.http_push(params)
    end

    def on_sms_reply_http_push(params)
      Smsim::SmsRepliesParser.http_push(params)
    end

    def pull_notification_deliveries_and_sms_replies_report(batch_size = 100)
      @report_puller.pull_delivery_notifications_and_sms_replies(batch_size)
    end

  end

end

