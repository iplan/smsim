require 'spec_helper'

describe Smsim::XmlRequestBuilder do

  describe '#build_send_sms' do
    let(:options){ {:username => 'alex', :password => 'pass', :reply_to_number => '0501234567', :message_id => '123'} }
    let(:message){ 'my message text' }
    let(:phone){ '0541234567' }
    let(:xml){ Smsim::XmlRequestBuilder.build_send_sms(message, phone, options) }
    let(:xml_doc){ Nokogiri::XML(xml) }

    it 'should raise error if text is blank' do
      lambda{ Smsim::XmlRequestBuilder.build_send_sms('', phone, options) }.should raise_error(ArgumentError)
    end

    it 'should raise error if phone is blank' do
      lambda{ Smsim::XmlRequestBuilder.build_send_sms(message, '', options) }.should raise_error(ArgumentError)
    end

    it 'should raise error if either username or password are missing from options' do
      lambda{ Smsim::XmlRequestBuilder.build_send_sms(message, phone, :password => 'pass') }.should raise_error(ArgumentError)
      lambda{ Smsim::XmlRequestBuilder.build_send_sms(message, phone, :username => 'alex') }.should raise_error(ArgumentError)
    end

    it 'should have username and password' do
      xml_doc.css('Inforu User Username').text.should == options[:username]
      xml_doc.css('Inforu User Password').text.should == options[:password]
    end

    it 'should have message text' do
      xml_doc.css('Inforu Content Message').text.should == message
    end

    it 'should have recepients phone number' do
      xml_doc.css('Inforu Recipients PhoneNumber').text.should == phone
    end

    it 'should have recepients phone numbers separated by ; without spaces' do
      phones = ['0541234567', '0541234568', '0541234569']
      xml_doc = Nokogiri::XML(Smsim::XmlRequestBuilder.build_send_sms(message, phones, options))
      xml_doc.css('Inforu Recipients PhoneNumber').text.should == phones.join(';')
    end

    it 'should have sender number' do
      xml_doc.css('Inforu Settings SenderNumber').text.should == options[:reply_to_number]
    end

    it 'should have message_id' do
      xml_doc.css('Inforu Settings CustomerMessageId').text.should == options[:message_id]
    end

    it 'should have delivery notification url with gateway_user if specified' do
      xml_doc.css('Inforu Settings DeliveryNotificationUrl').text.should be_blank
      
      xml_doc = Nokogiri::XML(Smsim::XmlRequestBuilder.build_send_sms(message, phone, options.update(:delivery_notification_url => 'http://google.com')))
      xml_doc.css('Inforu Settings DeliveryNotificationUrl').text.should == "http://google.com?gateway_user=#{options[:username]}"
    end

  end

end
