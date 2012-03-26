require 'spec_helper'

describe Smsim::PhoneNumberUtils do
  let(:utils) { Smsim::PhoneNumberUtils }

  describe '#valid_cellular_phone?' do
    it 'should not be valid without country code' do
      utils.valid_cellular_phone?('0545290862').should be_false
    end

    it 'should not be valid for landline phones' do
      utils.valid_cellular_phone?('035447037').should be_false
      utils.valid_cellular_phone?('97235447037').should be_false
    end

    it 'should not be valid with country code but of different lenth' do
      utils.valid_cellular_phone?('9725452908622').should be_false
      utils.valid_cellular_phone?('97254529086').should be_false
    end

    it 'should be valid with country code' do
      utils.valid_cellular_phone?('972545290862').should be_true
    end
  end

end
