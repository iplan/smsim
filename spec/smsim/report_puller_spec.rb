require 'spec_helper'

describe Smsim::ReportPuller do
  let(:request_uri) { Smsim::config.urls[:delivery_notifications_and_sms_replies_report_pull] }
  let(:puller) { Smsim::ReportPuller.new(:username => 'alex', :password => 'pass', :wsdl_url => request_uri) }
  let(:sender_number){ '0529992080' }
  let(:sender_number_with_country_code){ '972529992080' }

  describe '#pull_delivery_notifications_and_sms_replies' do
    let(:notifications) do
      [
        {'PhoneNumber' => '0541234567', 'Status' => 2, 'NotificationDate' => '22/03/2012 17:49:14', 'SenderNumber' => sender_number, 'SegmentsNumber' => '1', 'CustomerMessageId' => 'id1234', 'StatusDescription' => 'OK'},
        {'PhoneNumber' => '0541234568', 'Status' => -2, 'NotificationDate' => '22/03/2012 17:29:14', 'SenderNumber' => sender_number, 'SegmentsNumber' => '2', 'CustomerMessageId' => 'id12345', 'StatusDescription' => 'Not received'},
        {'PhoneNumber' => '0541234569', 'Status' => -4, 'NotificationDate' => '22/03/2012 23:49:14', 'SenderNumber' => sender_number, 'SegmentsNumber' => '3', 'CustomerMessageId' => 'id123456', 'StatusDescription' => 'Hasum'},
      ]
    end
    let(:replies) do
      [
        {'PhoneNumber' => '0541234567', 'SentMessage' => 'alex is king', 'NotificationDate' => '22/03/2012 17:49:14', 'SenderNumber' => sender_number},
        {'PhoneNumber' => '0541234568', 'SentMessage' => 'kak dila?', 'NotificationDate' => '22/03/2012 17:29:14', 'SenderNumber' => sender_number},
        {'PhoneNumber' => '0541234569', 'SentMessage' => 'asdf', 'NotificationDate' => '22/03/2012 23:49:14', 'SenderNumber' => sender_number},
      ]
    end

    it 'should raise GatewayError when response Status is not one of expected strings' do
      XmlResponseStubs.stub_request_with_pull_notifications_response(self, :status => "asdf")
      lambda { puller.pull_delivery_notifications_and_sms_replies }.should raise_error(Smsim::Errors::GatewayError)
    end

    #it 'should raise GatewayError when response BatchSize is greater than 0 but no messages included' do
    #  XmlResponseStubs.stub_request_with_pull_notifications_response(self, :status => "OK", :batch_size => 3)
    #  lambda{ puller.pull_delivery_notifications_and_sms_replies }.should raise_error(Smsim::Errors::GatewayError)
    #end

    it 'should return response with status and batch_size if no messages included' do
      XmlResponseStubs.stub_request_with_pull_notifications_response(self, :status => "OK", :notifications => [])
      response = puller.pull_delivery_notifications_and_sms_replies
      response.should be_present
      response.status.should == 1
      response.batch_size.should == 0
    end

    context 'when report contains delivery notifications' do
      it 'should return response with notifications array' do
        XmlResponseStubs.stub_request_with_pull_notifications_response(self, :status => "OK")
        report = puller.pull_delivery_notifications_and_sms_replies
        report.should be_present
        report.status.should == 1
        report.batch_size.should == 1
        report.errors.should be_empty
        report.notifications.should be_a(Array)
        report.notifications.count.should == 1
      end

      it 'should return response with notifications with typecasted properties ' do
        XmlResponseStubs.stub_request_with_pull_notifications_response(self, :status => "OK", :notifications => notifications)
        report = puller.pull_delivery_notifications_and_sms_replies
        report.status.should == 1
        report.batch_size.should == 3
        report.notifications.count.should == 3
        report.errors.should be_empty

        m1 = report.notifications[0]
        m1.gateway_status.should == 2
        m1.completed_at.strftime('%d/%m/%Y %H:%M:%S').should == '22/03/2012 17:49:14'
        m1.parts_count.should == 1
        m1.phone.should == '972541234567'
        m1.reply_to_phone.should == sender_number_with_country_code
        m1.message_id.should == 'id1234'

        m2 = report.notifications[1]
        m2.gateway_status.should == -2
        m2.phone.should == '972541234568'
        m2.reply_to_phone.should == sender_number_with_country_code
        m2.completed_at.strftime('%d/%m/%Y %H:%M:%S').should == '22/03/2012 17:29:14'
        m2.parts_count.should == 2
        m2.message_id.should == 'id12345'

        m3 = report.notifications[2]
        m3.gateway_status.should == -4
        m3.phone.should == '972541234569'
        m3.reply_to_phone.should == sender_number_with_country_code
        m3.completed_at.strftime('%d/%m/%Y %H:%M:%S').should == '22/03/2012 23:49:14'
        m3.parts_count.should == 3
        m3.message_id.should == 'id123456'
      end

      it 'should parsed notifications that are succeeded and add to errors those that do not' do
        notifications.first['Status'] = 'asdf'
        XmlResponseStubs.stub_request_with_pull_notifications_response(self, :status => "OK", :notifications => notifications)
        response = puller.pull_delivery_notifications_and_sms_replies
        response.status.should == 1
        response.batch_size.should == 3
        response.notifications.count.should == 2
        response.errors.count.should == 1
      end
    end

    context 'when report contains sms replies' do
      it 'should return response with replies array' do
        XmlResponseStubs.stub_request_with_pull_notifications_response(self, :status => "OK", :replies => replies, :notifications => [])
        report = puller.pull_delivery_notifications_and_sms_replies
        report.should be_present
        report.status.should == 1
        report.batch_size.should == 3
        report.errors.should be_empty
        report.replies.should be_a(Array)
        report.replies.count.should == 3
      end

      it 'should return response with replies with typecasted properties ' do
        XmlResponseStubs.stub_request_with_pull_notifications_response(self, :status => "OK", :replies => replies, :notifications => [])
        report = puller.pull_delivery_notifications_and_sms_replies
        report.status.should == 1
        report.batch_size.should == 3
        report.replies.count.should == 3
        report.errors.should be_empty

        m1 = report.replies[0]
        m1.received_at.strftime('%d/%m/%Y %H:%M:%S').should == '22/03/2012 17:49:14'
        m1.phone.should == '972541234567'
        m1.reply_to_phone.should == sender_number_with_country_code
        m1.text.should == 'alex is king'

        m2 = report.replies[1]
        m2.received_at.strftime('%d/%m/%Y %H:%M:%S').should == '22/03/2012 17:29:14'
        m2.phone.should == '972541234568'
        m2.reply_to_phone.should == sender_number_with_country_code
        m2.text.should == 'kak dila?'

        m3 = report.replies[2]
        m3.received_at.strftime('%d/%m/%Y %H:%M:%S').should == '22/03/2012 23:49:14'
        m3.phone.should == '972541234569'
        m3.reply_to_phone.should == sender_number_with_country_code
        m3.text.should == 'asdf'
      end

      it 'should parsed replies that are succeeded and add to errors those that do not' do
        replies.first['NotificationDate'] = 'asdf'
        XmlResponseStubs.stub_request_with_pull_notifications_response(self, :status => "OK", :replies => replies, :notifications => [])
        response = puller.pull_delivery_notifications_and_sms_replies
        response.status.should == 1
        response.batch_size.should == 3
        response.replies.count.should == 2
        response.errors.count.should == 1
      end
    end

  end
end
