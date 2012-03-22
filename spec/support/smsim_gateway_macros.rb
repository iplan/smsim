class XmlResponseStubs

  class << self
    def sms_send_response(response_options = {})
      response_options = {:status => 1, :description => 'received ok', :number_of_recipients => 0}.update(response_options)
      doc = ::Nokogiri::XML(FileMacros.load_xml_file('SmsSendResponse.xml'))
      doc.at_css('Status').content = response_options[:status]
      doc.at_css('Description').content = response_options[:description]
      doc.at_css('NumberOfRecipients').content = response_options[:number_of_recipients]
      doc.to_xml
    end

    def wrap_in_soap_envelope_response(response_root_node)
      doc = ::Nokogiri::XML(FileMacros.load_xml_file('EnvelopeResponse.soap.xml'))
      doc.at_css('soap|Body').add_child response_root_node
      doc.to_xml
    end

    def delivery_report_pull_response(response_options = {})
      response_options = {:status => 'OK', :messages => [
        'PhoneNumber' => '0541234567',
        'Status' => 2
      ]}.update(response_options)
      doc = ::Nokogiri::XML(FileMacros.load_xml_file('PullClientNotificationResponse.soap.xml'))
      doc.at_css('Status').content = response_options[:status]
      doc.at_css('BatchSize').content = response_options[:messages].count

      if response_options[:messages].count == 0
        doc.at_css('Messages').remove
      else
        msg_template_node = doc.at_css('Messages Message').remove
        for msg in response_options[:messages]
          node = msg_template_node.dup
          node.default_namespace = "http://tempuri.org/"
          msg.each do |key, value|
            node.at_css(key.to_s.camelcase).content = value
          end
          doc.at_css('Messages').add_child(node)
        end
      end
      wrap_in_soap_envelope_response(doc.root)
    end

    def stub_request_with_sms_send_response(example, options = {})
      options = {:http_code => 200}.update(options)
      example.stub_request(:any, Smsim::Gateway.urls.send_sms).to_return(:status => options.delete(:http_code), :body => XmlResponseStubs.sms_send_response(options))
    end

    def stub_request_with_pull_notifications_response(example, options = {})
      options = {:http_code => 200}.update(options)
      http_code = options.delete(:http_code)
      example.stub_request(:get, Smsim::Gateway.urls.delivery_report_pull).to_return(:status => http_code, :body => FileMacros.load_xml_file('ClientServices.asmx.wsdl.xml'))
      example.stub_request(:post, Smsim::Gateway.urls.delivery_report_pull.gsub('?WSDL', '')).to_return(:status => http_code, :body => XmlResponseStubs.delivery_report_pull_response(options))
    end

    def sms_reply_http_xml_string(values_hash = {})
      doc = ::Nokogiri::XML(FileMacros.load_xml_file('SmsReplyPush.xml'))
      root = doc.at_css('IncomingData')
      values_hash.each do |key, value|
        root.at_css(key.to_s.camelcase).content = value
      end
      root.to_s
    end
  end

end