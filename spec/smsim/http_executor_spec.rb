require 'spec_helper'

describe Smsim::HttpExecutor do
  let(:request_uri){ "#{Smsim::HttpExecutor.send_sms_uri}" }

  describe '#parse_response' do
    it 'should raise HttpError if url not found' do
      stub_request(:any, request_uri).to_return(:status => 404)
      lambda{ Smsim::HttpExecutor.do_post(request_uri, :body => 'asdf') }.should raise_error(Smsim::HttpError)
    end

    it 'should return response object if url ok (200 http status)' do
      stub_request(:any, request_uri).to_return(:status => 200)
      Smsim::HttpExecutor.do_get(request_uri).class.should == HTTParty::Response
    end
  end

  describe '#send_sms' do
    it 'should raise GatewayError when response Status is not an integer negative' do
      stub_request(:any, request_uri).to_return(:status => 200, :body => SmsimGatewayMacros.sms_send_response("asdf"))
      lambda{ Smsim::HttpExecutor.send_sms('xml') }.should raise_error(Smsim::GatewayError)
    end
    
    it 'should raise GatewayError when response NumberOfRecipients is not an integer negative' do
      stub_request(:any, request_uri).to_return(:status => 200, :body => SmsimGatewayMacros.sms_send_response(1, "desc", "asdf"))
      lambda{ Smsim::HttpExecutor.send_sms('xml') }.should raise_error(Smsim::GatewayError)
    end

    it 'should return XmlResponse with status, description and number of receipents initialized' do
      stub_request(:any, request_uri).to_return(:status => 200, :body => SmsimGatewayMacros.sms_send_response(1, "desc", 2))
      response = Smsim::HttpExecutor.send_sms('xml')
      response.should be_a(Smsim::XmlResponse)
      response.status.should == 1
      response.description.should == "desc"
      response.number_of_recipients.should == 2
    end
  end

end
