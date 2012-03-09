class SmsimGatewayMacros

  class << self
    def sms_send_response(code, description = '', number_of_recipients = 0)
      xml = Builder::XmlMarkup.new( :indent => 2 )
      xml.instruct!
      xml.Result do |root|
        root.Status code
        root.Description description
        root.NumberOfRecipients number_of_recipients
      end
    end
  end

end