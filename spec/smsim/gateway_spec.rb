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



end
