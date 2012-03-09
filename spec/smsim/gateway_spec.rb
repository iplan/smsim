require 'spec_helper'

describe Smsim::Gateway do

  context "when creating" do
    it 'should raise ArgumentError if username or password are blank' do
      lambda{ Smsim::Gateway.new('', 'pass') }.should raise_error(ArgumentError)
      lambda{ Smsim::Gateway.new('user', '') }.should raise_error(ArgumentError)
    end

    it 'should create gateway with given user and password' do
      g = Smsim::Gateway.new('user', 'pass')
      g.username.should == 'user'
    end
  end

  describe '#send_sms' do
    let(:g){ Smsim::Gateway.new('user', 'pass') }

    before :each do
      XmlResponseStubs.stub_request_with_sms_send_response(self)
    end

    it 'should pass username, password and message_id to request builder' do
      Smsim::XmlRequestBuilder.should_receive(:build_send_sms).with('alex is king', '054123456', hash_including(:message_id))
      g.send_sms('alex is king', '054123456')
    end

    it 'should pass reply_to_number and delivery_notification_url' do
      g = Smsim::Gateway.new('user', 'pass', :reply_to_number => '0501234567')
      Smsim::XmlRequestBuilder.should_receive(:build_send_sms).with('alex is king', '054123456', hash_including(:message_id, :reply_to_number => '0501234567'))
      g.send_sms('alex is king', '054123456')

      g = Smsim::Gateway.new('user', 'pass', :delivery_notification_url => 'google.com')
      Smsim::XmlRequestBuilder.should_receive(:build_send_sms).with('alex is king', '054123456', hash_including(:message_id, :delivery_notification_url => 'google.com'))
      g.send_sms('alex is king', '054123456')
    end

    it 'should return generated message id when send succeeds' do
      mid = g.send_sms('alex is king', '054123456')
      mid.should be_present
      mid.should be_a(String)
      mid.length.should > 10
    end
  end

end
