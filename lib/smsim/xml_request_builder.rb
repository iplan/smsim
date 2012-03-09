require 'builder'

module Smsim
  class XmlRequestBuilder

    def self.build_send_sms(message_text, phones, options = {})
      raise ArgumentError.new("Text must be at least 1 character long") if message_text.blank?
      raise ArgumentError.new("Phones must include at least one phone") if phones.blank?
      raise ArgumentError.new("Username and password must be present in options") if options[:username].blank? || options[:password].blank?
      raise ArgumentError.new("Message id must be present in options") if options[:customer_message_id].blank?
      phones = phones.to_a unless phones.is_a?(Array)
      raise ArgumentError.new("Max phones number is 100") if phones.count > 100

      # enhance it with gateway_user parameter
      if options[:delivery_notification_url].present?
        prefix = options[:delivery_notification_url].include?('?') ? '&' : '?'
        options[:delivery_notification_url] << "#{prefix}gateway_user=#{options[:username]}"
      end

      xml = Builder::XmlMarkup.new(:indent => 2)
      xml.instruct!
      xml.Inforu do |root|
        root.User do |user|
          user.Username options[:username]
          user.Password options[:password]
        end
        root.Content(:Type => 'sms') do |content|
          content.Message message_text
        end
        root.Recipients do |recipients|
          recipients.PhoneNumber phones.join(';')
        end
        root.Settings do |settings|
          settings.SenderNumber options[:reply_to_number]
          settings.CustomerMessageId options[:customer_message_id]
          settings.DeliveryNotificationUrl options[:delivery_notification_url] if options[:delivery_notification_url].present?
        end
      end
    end

  end
end

