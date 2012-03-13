require 'ostruct'
module Smsim
  module GatewayUrls
    @@urls = OpenStruct.new({
      :send_sms => 'http://api.smsim.co.il/SendMessageXml.ashx',
      :delivery_report_pull => 'http://api.inforu.co.il/ClientServices.asmx?WSDL'
    })
    def urls; @@urls; end
  end
end