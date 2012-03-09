class XmlResponseStubs

  class << self
    def sms_send_response(response_options = {})
      response_options = {:status => 1, :description => 'received ok', :number_of_recipients => 0}.update(response_options)
      xml = Builder::XmlMarkup.new( :indent => 2 )
      xml.instruct!
      xml.Result do |root|
        root.Status response_options[:status]
        root.Description response_options[:description]
        root.NumberOfRecipients response_options[:number_of_recipients]
      end
    end

    def stub_request_with_sms_send_response(example, options = {})
      options = {:http_code => 200}.update(options)
      example.stub_request(:any, Smsim::HttpExecutor.urls.send_sms).to_return(:status => options.delete(:http_code), :body => XmlResponseStubs.sms_send_response(options))
    end
  end

end