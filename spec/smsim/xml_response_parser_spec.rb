require 'spec_helper'

describe Smsim::XmlResponseParser do

  describe '#parse_sms_send_response' do
    let(:request_uri){ Smsim::HttpExecutor.urls.send_sms }
    
    it 'should raise XmlResponseError when response Status is not an integer' do
      XmlResponseStubs.stub_request_with_sms_send_response(self, :status => "asdf")
      lambda{ Smsim::HttpExecutor.send_sms('xml') }.should raise_error(Smsim::Errors::XmlResponseError)
    end

    it 'should raise XmlResponseError when response NumberOfRecipients is not an integer' do
      XmlResponseStubs.stub_request_with_sms_send_response(self, :status => '1', :description => "received ok", :number_of_recipients => 'df')
      lambda{ Smsim::HttpExecutor.send_sms('xml') }.should raise_error(Smsim::Errors::XmlResponseError)
    end

    it 'should return XmlResponse with status, description and number of recipients initialized' do
      XmlResponseStubs.stub_request_with_sms_send_response(self, :status => '1', :description => "received ok", :number_of_recipients => '2')
      response = Smsim::HttpExecutor.send_sms('xml')
      response.status.should == 1
      response.description.should == "received ok"
      response.number_of_recipients.should == 2
    end
  end

end
