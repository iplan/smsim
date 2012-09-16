require 'spec_helper'

describe Smsim::Gateway do
  let(:options){ {:username => 'user', :password => 'pass'} }
  let(:gateway){ Smsim::Gateway.new(options) }

  context "when creating" do
    it 'should raise ArgumentError if username, password are blank' do
      lambda{ Smsim::Gateway.new(options.update(:username => '')) }.should raise_error(ArgumentError)
      lambda{ Smsim::Gateway.new(options.update(:password => '')) }.should raise_error(ArgumentError)
    end

    it 'should create gateway with given user and password' do
      g = Smsim::Gateway.new(options)
      g.username.should == options[:username]
      g.password.should == options[:password]
    end
  end

  describe '#send_sms' do
    let(:g){ Smsim::Gateway.new(options) }

    before :each do
      XmlResponseStubs.stub_request_with_sms_send_response(self, g.inforu_urls[:send_sms])
    end

    it 'should return generated message info with message_id when send succeeds' do
      result = g.send_sms('alex is king', '972541234567', :sender_number => '972541234567')
      result.should be_present
      result.message_id.should be_present
      result.message_id.length.should > 10
    end
  end

end
