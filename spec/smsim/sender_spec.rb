require 'spec_helper'

describe Smsim::SmsSender do
  let(:gateway){ Smsim::Gateway.new(:username => 'alex', :password => 'pass') }
  let(:sender){ gateway.sms_sender }

  describe '#send_sms' do
    let(:message){ 'my message text' }
    let(:phone){ '972541234567' }

    it 'should raise error if text is blank' do
      lambda{ sender.send_sms('', phone) }.should raise_error(ArgumentError)
    end

    it 'should raise error if phone is blank' do
      lambda{ sender.send_sms(message, '') }.should raise_error(ArgumentError)
    end

    it 'should raise error if phone is not valid cellular phone' do
      lambda{ sender.send_sms(message, '0541234567') }.should raise_error(ArgumentError)
      lambda{ sender.send_sms(message, '541234567') }.should raise_error(ArgumentError)
    end

    it 'should raise error if sender_number is not valid cellular phone' do
      lambda{ sender.send_sms(message, phone, :sender_number => '1234') }.should raise_error(ArgumentError)
      lambda{ sender.send_sms(message, phone, :sender_number => '0545290862') }.should raise_error(ArgumentError)
    end

  end

  describe '#build_send_sms_xml' do
    let(:message){ 'my message text' }
    let(:phones){ ['0541234567'] }
    let(:xml_doc){ Nokogiri::XML(sender.build_send_sms_xml(message, phones, '123', :sender_number => '972541234567')) }

    it 'should have username and password' do
      xml_doc.at_css('Inforu User Username').text.should == 'alex'
      xml_doc.at_css('Inforu User Password').text.should == 'pass'
    end

    it 'should have message text' do
      xml_doc.at_css('Inforu Content Message').text.should == message
    end

    it 'should have recepients phone number' do
      xml_doc.at_css('Inforu Recipients PhoneNumber').text.should == phones.first
    end

    it 'should have recepients phone numbers separated by ; without spaces' do
      phones << '0541234568' << '0541234569'
      xml_doc.at_css('Inforu Recipients PhoneNumber').text.should == phones.join(';')
    end

    it 'should have sender number' do
      xml_doc.at_css('Inforu Settings SenderNumber').text.should == '0541234567'
    end

    it 'should have message_id' do
      xml_doc.at_css('Inforu Settings CustomerMessageId').text.should == '123'
    end

    it 'should have delivery notification url if specified' do
      gateway = Smsim::Gateway.new(:username => 'alex', :password => 'pass')
      xml_doc = Nokogiri::XML(gateway.sms_sender.build_send_sms_xml(message, phones, '123', :sender_number => '972501234567', :delivery_notification_url => 'http://google.com?auth=1234&alex=king'))
      xml_doc.at_css('Inforu Settings DeliveryNotificationUrl').text.should == "http://google.com?auth=1234&alex=king"
    end

    it 'should not have delivery notification url if not specified' do
      xml_doc.at_css('Inforu Settings DeliveryNotificationUrl').should be_nil
    end

  end

  describe '#verify_response_code' do
    let(:request_uri){ sender.api_send_sms_url }

    it 'should raise HttpResponseError if url not found' do
      stub_request(:any, request_uri).to_return(:status => 404)
      lambda{ sender.verify_http_response_code(sender.class.post(request_uri, :body => 'asdf')) }.should raise_error(Smsim::GatewayError)
    end

    it 'should not raise error url if response code is ok (200 http status)' do
      stub_request(:any, request_uri).to_return(:status => 200, :body => 'response body')
      sender.verify_http_response_code(sender.class.post(request_uri)).should be_true
    end
  end

  describe '#parse_response_xml' do
    let(:phone){ '972541234567' }
    it 'should raise XmlResponseError when response Status is not an integer' do
      XmlResponseStubs.stub_request_with_sms_send_response(self, sender.api_send_sms_url, :status => "asdf")
      lambda{ sender.send_sms('message', phone, :sender_number => '972547654321') }.should raise_error(Smsim::GatewayError)
    end

    it 'should raise XmlResponseError when response NumberOfRecipients is not an integer' do
      XmlResponseStubs.stub_request_with_sms_send_response(self, sender.api_send_sms_url, :status => '1', :description => "received ok", :number_of_recipients => 'df')
      lambda{ sender.send_sms('message', phone, :sender_number => '972547654321') }.should raise_error(Smsim::GatewayError)
    end

    it 'should return XmlResponse with status, message_id, description and number of recipients initialized' do
      XmlResponseStubs.stub_request_with_sms_send_response(self, sender.api_send_sms_url, :status => '1', :description => "received ok", :number_of_recipients => '2')
      response = sender.send_sms('message', phone, :sender_number => '972547654321')
      response.status.should == 1
      response.message_id.should be_present
      response.description.should == "received ok"
      response.number_of_recipients.should == 2
      response.sender_number.should == '972547654321'
    end
  end

end
