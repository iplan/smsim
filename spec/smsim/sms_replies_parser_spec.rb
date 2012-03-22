require 'spec_helper'

describe Smsim::SmsRepliesParser do
  let(:parser) { Smsim::SmsRepliesParser }

  describe '#http_push' do
    let(:reply_values) { {'PhoneNumber' => '0541234567', 'Message' => 'kak dila', 'ShortCode' => '0529992090'} }
    let(:reply) { parser.http_push({'IncomingXML' => XmlResponseStubs.sms_reply_http_xml_string(reply_values)}) }

    it 'should raise DeliveryNotificationError if parameters are missing or not of expected type' do
      lambda { parser.http_push({'Puki' => 'asdf'}) }.should raise_error(Smsim::Errors::SmsReplyError)
    end

    it 'should return SmsReply with all fields initialized' do
      Time.stub(:now).and_return(Time.utc(2011, 8, 1, 11, 15, 00))

      reply.should be_present
      reply.phone.should == '0541234567'
      reply.text.should == 'kak dila'
      reply.replied_to.should == '0529992090'
      reply.received_at.strftime('%d/%m/%Y %H:%M:%S').should == '01/08/2011 11:15:00'
    end
  end

  describe '#delivery_report_pull' do
    let(:request_uri) { Smsim::Gateway.urls.delivery_report_pull }
    let(:messages) do
      [
        {'PhoneNumber' => '0541234567', 'Status' => 2, 'NotificationDate' => '22/03/2012 17:49:14', 'SegmentsNumber' => '1', 'CustomerMessageId' => 'id1234', 'StatusDescription' => 'OK'},
        {'PhoneNumber' => '0541234568', 'Status' => -2, 'NotificationDate' => '22/03/2012 17:29:14', 'SegmentsNumber' => '2', 'CustomerMessageId' => 'id12345', 'StatusDescription' => 'Not received'},
        {'PhoneNumber' => '0541234569', 'Status' => -4, 'NotificationDate' => '22/03/2012 23:49:14', 'SegmentsNumber' => '3', 'CustomerMessageId' => 'id123456', 'StatusDescription' => 'Hasum'},
      ]
    end

    it 'should raise XmlResponseError when response Status is not one of expected strings' do
      XmlResponseStubs.stub_request_with_pull_notifications_response(self, :status => "asdf")
      lambda { Smsim::DeliveryNotificationsParser.delivery_report_pull('alex', 'pass') }.should raise_error(Smsim::Errors::DeliveryNotificationError)
    end

    #it 'should raise XmlResponseError when response BatchSize is greater than 0 but no messages included' do
    #  XmlResponseStubs.stub_request_with_pull_notifications_response(self, :status => "OK", :batch_size => 3)
    #  lambda{ Smsim::DeliveryNotificationsParser.delivery_report_pull('alex', 'pass') }.should raise_error(Smsim::Errors::XmlResponseError)
    #end

    it 'should return response with status and batch_size if no messages included' do
      XmlResponseStubs.stub_request_with_pull_notifications_response(self, :status => "OK", :messages => [])
      response = Smsim::DeliveryNotificationsParser.delivery_report_pull('alex', 'pass')
      response.should be_present
      response.status.should == 1
      response.batch_size.should == 0
    end

    it 'should return response with messages array of DeliveryNotification' do
      XmlResponseStubs.stub_request_with_pull_notifications_response(self, :status => "OK")
      response = Smsim::DeliveryNotificationsParser.delivery_report_pull('alex', 'pass')
      response.should be_present
      response.status.should == 1
      response.batch_size.should == 1
      response.messages.should be_a(Array)
      response.messages.count.should == 1
      response.messages.first.should be_a(Smsim::DeliveryNotification)
      response.errors.count.should == 0
    end

    it 'should return response with messages with typecasted properties ' do
      XmlResponseStubs.stub_request_with_pull_notifications_response(self, :status => "OK", :messages => messages)
      response = Smsim::DeliveryNotificationsParser.delivery_report_pull('alex', 'pass')
      response.status.should == 1
      response.batch_size.should == 3
      response.messages.count.should == 3
      response.errors.count.should == 0

      m1 = response.messages[0]
      m1.status.should == 2
      m1.completed_at.strftime('%d/%m/%Y %H:%M:%S').should == '22/03/2012 17:49:14'
      m1.parts_count.should == 1
      m1.message_id.should == 'id1234'

      m2 = response.messages[1]
      m2.status.should == -2
      m2.completed_at.strftime('%d/%m/%Y %H:%M:%S').should == '22/03/2012 17:29:14'
      m2.parts_count.should == 2
      m2.message_id.should == 'id12345'

      m3 = response.messages[2]
      m3.status.should == -4
      m3.completed_at.strftime('%d/%m/%Y %H:%M:%S').should == '22/03/2012 23:49:14'
      m3.parts_count.should == 3
      m3.message_id.should == 'id123456'
    end

    it 'should parsed messages that are succeeded and add to errors those that do not' do
      ms = messages
      ms.first['Status'] = 'asdf'
      XmlResponseStubs.stub_request_with_pull_notifications_response(self, :status => "OK", :messages => ms)
      response = Smsim::DeliveryNotificationsParser.delivery_report_pull('alex', 'pass')
      response.status.should == 1
      response.batch_size.should == 3
      response.messages.count.should == 2
      response.errors.count.should == 1
    end

  end
end
