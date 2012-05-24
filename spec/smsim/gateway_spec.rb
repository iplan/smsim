require 'spec_helper'

describe Smsim::Gateway do
  let(:options){ {:username => 'user', :password => 'pass', :sender_number => '972541234567'} }
  let(:gateway){ Smsim::Gateway.new(options) }

  it 'should return sender number without 972 country code ' do
    gateway.sender_number_without_country_code.should == '0541234567'
  end

  context "when creating" do
    it 'should raise ArgumentError if username, password or sender_number are blank' do
      lambda{ Smsim::Gateway.new(options.update(:username => '')) }.should raise_error(ArgumentError)
      lambda{ Smsim::Gateway.new(options.update(:password => '')) }.should raise_error(ArgumentError)
      lambda{ Smsim::Gateway.new(options.update(:sender_number => '')) }.should raise_error(ArgumentError)
    end

    it 'should raise error if sender_number is not valid cellular phone' do
      lambda{ Smsim::Gateway.new(options.update(:sender_number => '1234')) }.should raise_error(ArgumentError)
      lambda{ Smsim::Gateway.new(options.update(:sender_number => '0545290862')) }.should raise_error(ArgumentError)
    end

    it 'should create gateway with given user and password' do
      g = Smsim::Gateway.new(options)
      g.username.should == options[:username]
      g.password.should == options[:password]
      g.sender_number.should == options[:sender_number]
    end
  end

  describe '#send_sms' do
    let(:g){ Smsim::Gateway.new(options) }

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
