require 'spec_helper'

describe Smsim::XmlResponseParser do

  describe '#parse_sms_send_response' do
    let(:request_uri){ Smsim::HttpExecutor.urls.send_sms }
    
    it 'should raise XmlResponseError when response Status is not an integer' do
      stub_request(:any, request_uri).to_return(:status => 200, :body => XmlResponseStubs.sms_send_response("asdf"))
      lambda{ Smsim::HttpExecutor.send_sms('xml') }.should raise_error(Smsim::Errors::XmlResponseError)
    end

    it 'should raise XmlResponseError when response NumberOfRecipients is not an integer' do
      stub_request(:any, request_uri).to_return(:status => 200, :body => XmlResponseStubs.sms_send_response(1, "desc", "asdf"))
      lambda{ Smsim::HttpExecutor.send_sms('xml') }.should raise_error(Smsim::Errors::XmlResponseError)
    end

    it 'should return XmlResponse with status, description and number of recipients initialized' do
      stub_request(:any, request_uri).to_return(:status => 200, :body => XmlResponseStubs.sms_send_response(1, "desc", 2))
      response = Smsim::HttpExecutor.send_sms('xml')
      response.status.should == 1
      response.description.should == "desc"
      response.number_of_recipients.should == 2
    end
  end

end
