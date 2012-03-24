require 'spec_helper'

describe Smsim::DeliveryNotificationsParser do
  let(:parser) { Smsim::DeliveryNotificationsParser }

  describe '#http_push' do
    let(:http_params) { {'Status' => '1', 'CustomerMessageId' => 'a1', 'SegmentsNumber' => '3', 'PhoneNumber' => '0545123456', 'NotificationDate' => "09/03/2012 23:29:12"} }
    let(:notification) { parser.http_push(http_params) }

    it 'should raise GatewayError if parameters are missing or not of expected type' do
      ['PhoneNumber', 'Status', 'CustomerMessageId', 'SegmentsNumber'].each do |p|
        params = http_params.clone
        params.delete(p)
        lambda { parser.http_push(params) }.should raise_error(Smsim::Errors::GatewayError)
      end

      lambda { parser.http_push(http_params.update('Status' => 'asdf')) }.should raise_error(Smsim::Errors::GatewayError)
      lambda { parser.http_push(http_params.update('SegmentsNumber' => 'asdf')) }.should raise_error(Smsim::Errors::GatewayError)
    end

    it 'should return DeliveryNotification with all fields initialized' do
      notification.should be_present
      notification.message_id.should == 'a1'
      notification.phone.should == '0545123456'
      notification.gateway_status.should be_a(Integer)
      notification.gateway_status.should == 1
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
    end

    it 'should be blocked when status is -4' do
      http_params.update('Status' => '-4')
      notification.should_not be_delivered
    end
  end

end
