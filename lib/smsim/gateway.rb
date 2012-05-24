require 'uuidtools'

module Smsim

  # NOTE: sender_number is always mandatory. if you want to be this gateway ONE way, provide non existing sender number, like 03-1234567
  # NOTE: sender_name is not support on all networks, on those that it is, the sms will be automatically one way
  class Gateway
    attr_reader :username, :password, :inforu_urls, :logger
    attr_reader :delivery_notification_url # url to which delivery notification will be sent (optional)
    attr_reader :sender_number, :sender_name

    attr_reader :sms_sender
    attr_reader :report_puller

    # Create new gateway with given +username+ and +password+
    # +config+ hash with the following keys:
    #   * +username+ - gateway user name
    #   * +password - gateway password
    #   * +gateway_type - gateway type (two_way or one_way)
    #   * delivery_notification_url - url to which delivery notification will be sent. might be nil and then no delivery notifications will be sent.
    #   * sender_number - to which number sms receiver will reply
    # These keys will be used when sending sms messages
    def initialize(config)
      [:username, :password, :sender_number, :gateway_type].each do |attr|
        raise ArgumentError.new("Missing required attribute #{attr}") if config[attr].blank?
      end
      @gateway_type = config[:gateway_type]
      @sender_number = config[:sender_number]
      @sender_name = config[:sender_name] if config[:sender_name].present?

      raise ArgumentError.new("Reply to number must be cellular or land line phone with 972 country code, was: #@sender_number") if !PhoneNumberUtils.valid_sender_number?(@sender_number, two_way?)
      raise ArgumentError.new("Sender name must be max 11 latin chars") if @sender_name.present? && !(@sender_name =~ /^[a-z]{3,11}$/i)
      raise ArgumentError.new("Sender name cannot be used in two way gateway") if @sender_name.present? && two_way?

      @logger = Logging.logger[self.class]
      @username = config[:username]
      @password = config[:password]
      @delivery_notification_url = config[:delivery_notification_url]

      @inforu_urls = Smsim.config.urls.merge(config[:urls] || {})
      @sms_sender = Sender.new(self)
      @report_puller = ReportPuller.new(self)
    end

    def two_way?
      @gateway_type == 'two_way'
    end

    def one_way?
      @gateway_type == 'two_way'
    end

    #def initialize2(username, password, options = {})
    #  @logger = Logging.logger[self.class]
    #  @options = options
    #  @urls = Smsim.config.urls.merge(@options.delete(:urls) || {})
    #  @username = username
    #  @password = password
    #  raise ArgumentError.new("Username and password must be present") if @username.blank? || @password.blank?
    #
    #  @sms_sender = Sender.new(options.merge(:username => username, :password => password, :http_post_url => @urls[:send_sms]))
    #  @report_puller = ReportPuller.new(options.merge(:username => username, :password => password, :wsdl_url => @urls[:delivery_notifications_and_sms_replies_report_pull]))
    #end

    # send +text+ string to the phones specified in +phones+ array
    # Returns response OpenStruct that contains:
    #  * +message_id+ - message id string. You must save this id if you want to receive delivery notifications via push/pull
    #  * +status+ - gateway status of sms send
    #  * +number_of_recipients+ - number of recipients the message was sent to
    def send_sms(text, phones)
      @sms_sender.send_sms(text, phones)
    end

    def sender_number_without_country_code
      @sender_number_without_country_code ||= self.sender_number.start_with?('972') ? self.sender_number.gsub('972', '0') : self.sender_number
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

