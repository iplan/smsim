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

    it 'should return generated message info with message_id when send succeeds' do
      result = g.send_sms('alex is king', '972541234567')
      result.should be_present
      result.message_id.should be_present
      result.message_id.length.should > 10
    end
  end

end
