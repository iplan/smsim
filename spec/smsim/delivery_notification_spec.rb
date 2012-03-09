require 'spec_helper'

describe Smsim::DeliveryNotification do

  describe '#parse_from_http_params' do
    let(:http_params){ {'Status' => '1', 'CustomerMessageId' => 'a1', 'SegmentsNumber' => '3', 'PhoneNumber' => '0545123456'} }
    let(:notification){ Smsim::DeliveryNotification.parse_from_http_params(http_params) }

    it 'should raise DeliveryNotificationError if parameters are missing or not of required tye' do
      ['PhoneNumber', 'Status', 'CustomerMessageId', 'SegmentsNumber'].each do |p|
        params = http_params.clone
        params.delete(p)
        lambda{ Smsim::DeliveryNotification.parse_from_http_params(params) }.should raise_error(Smsim::Errors::DeliveryNotificationError)
      end

      lambda{ Smsim::DeliveryNotification.parse_from_http_params(http_params.update('Status' => 'asdf')) }.should raise_error(Smsim::Errors::DeliveryNotificationError)
      lambda{ Smsim::DeliveryNotification.parse_from_http_params(http_params.update('SegmentsNumber' => 'asdf')) }.should raise_error(Smsim::Errors::DeliveryNotificationError)
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

end
