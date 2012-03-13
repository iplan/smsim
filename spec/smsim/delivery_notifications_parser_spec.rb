require 'spec_helper'

describe Smsim::DeliveryNotificationsParser do
  let(:parser) { Smsim::DeliveryNotificationsParser }

  describe '#http_push' do
    let(:http_params) { {'Status' => '1', 'CustomerMessageId' => 'a1', 'SegmentsNumber' => '3', 'PhoneNumber' => '0545123456', 'NotificationDate' => "09/03/2012 23:29:12"} }
    let(:notification) { parser.http_push(http_params) }

    it 'should raise DeliveryNotificationError if parameters are missing or not of expected type' do
      ['PhoneNumber', 'Status', 'CustomerMessageId', 'SegmentsNumber'].each do |p|
        params = http_params.clone
        params.delete(p)
        lambda { parser.http_push(params) }.should raise_error(Smsim::Errors::DeliveryNotificationError)
      end

      lambda { parser.http_push(http_params.update('Status' => 'asdf')) }.should raise_error(Smsim::Errors::DeliveryNotificationError)
      lambda { parser.http_push(http_params.update('SegmentsNumber' => 'asdf')) }.should raise_error(Smsim::Errors::DeliveryNotificationError)
    end

    it 'should return DeliveryNotification with all fields initialized' do
      notification.should be_present
      notification.message_id.should == 'a1'
      notification.phone.should == '0545123456'
      notification.status.should be_a(Integer)
      notification.status.should == 1
      notification.parts_count.should be_a(Integer)
      notification.parts_count.should == 3
      notification.completed_at.should be_present
      notification.completed_at.strftime('%d/%m/%Y %H:%M:%S').should == "09/03/2012 23:29:12"
    end

    it 'should be delivered when status is 2' do
      http_params.update('Status' => '2')
      notification.should be_delivered
      notification.should_not be_not_delivered
      notification.should_not be_blocked
    end

    it 'should be not delivered when status is -2' do
      http_params.update('Status' => '-2')
      notification.should_not be_delivered
      notification.should be_not_delivered
      notification.should_not be_blocked
    end

    it 'should be blocked when status is -4' do
      http_params.update('Status' => '-4')
      notification.should_not be_delivered
      notification.should_not be_not_delivered
      notification.should be_blocked
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
