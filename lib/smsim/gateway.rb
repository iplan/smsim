require 'uuidtools'

module Smsim

  # NOTE: sender_number is always mandatory. if you want to be this gateway ONE way, provide non existing sender number, like 03-1234567
  # NOTE: sender_name is not support on all networks, on those that it is, the sms will be automatically one way
  class Gateway
    attr_reader :username, :password, :inforu_urls, :time_zone, :logger

    attr_reader :sms_sender, :delivery_notification_parser, :sms_replies_parser, :report_puller

    # Create new gateway with given +username+ and +password+
    # +config+ hash with the following keys:
    #   * +username+ - gateway user name
    #   * +password - gateway password
    #   * +gateway_type - gateway type (two_way or one_way)
    #   * delivery_notification_url - url to which delivery notification will be sent. might be nil and then no delivery notifications will be sent.
    #   * sender_number - to which number sms receiver will reply
    # These keys will be used when sending sms messages
    def initialize(config)
      [:username, :password].each do |attr|
        raise ArgumentError.new("Missing required attribute #{attr}") if config[attr].blank?
      end

      @logger = Logging.logger[self.class]
      @username = config[:username]
      @password = config[:password]
      @delivery_notification_url = config[:delivery_notification_url]

      @time_zone = config[:time_zone] || 'Jerusalem'

      @inforu_urls = {
        :send_sms => 'http://api.smsim.co.il/SendMessageXml.ashx',
        :delivery_notifications_and_sms_replies_report_pull => 'http://api.inforu.co.il/ClientServices.asmx?WSDL'
      }.update(config[:urls] || {})

      @sms_sender = SmsSender.new(self)
      @delivery_notification_parser = DeliveryNotificationsParser.new(self)
      @report_puller = ReportPuller.new(self)
      @sms_replies_parser = SmsRepliesParser.new(self)
    end

    # send +text+ string to the +phones+ array of phone numbers
    # +options+ - is a hash of optional configuration that can be passed to sms sender:
    #  * +sender_name+ - sender name that will override gateway sender name
    #  * +sender_number+ - sender number that will override gateway sender number
    #  * +delivery_notification_url+ - url which will be invoked upon notification delivery
    # Returns response OpenStruct that contains:
    #  * +message_id+ - message id string. You must save this id if you want to receive delivery notifications via push/pull
    #  * +status+ - gateway status of sms send
    #  * +number_of_recipients+ - number of recipients the message was sent to
    def send_sms(text, phones, options = {})
      @sms_sender.send_sms(text, phones, options)
    end

    def on_delivery_notification_http_push(params)
      @delivery_notification_parser.http_push(params)
    end

    def on_sms_reply_http_push(params)
      @sms_replies_parser.http_push(params)
    end

    def pull_notification_deliveries_and_sms_replies_report(batch_size = 100)
      @report_puller.pull_delivery_notifications_and_sms_replies(batch_size)
    end

  end

end

