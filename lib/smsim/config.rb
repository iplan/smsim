require 'ostruct'
module Smsim

  def self.config
    @@configuration ||= OpenStruct.new({
      :urls => {
        :send_sms => 'http://api.smsim.co.il/SendMessageXml.ashx',
        :delivery_notifications_and_sms_replies_report_pull => 'http://api.inforu.co.il/ClientServices.asmx?WSDL'
      }
    })
    @@configuration
  end
  
end