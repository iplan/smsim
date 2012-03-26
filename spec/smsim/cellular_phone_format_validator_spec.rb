require 'spec_helper'

describe Smsim::CellularPhoneFormatValidator do
  let(:v) { Smsim::CellularPhoneFormatValidator }

  describe '#valid?' do
    it 'should not be valid without country code' do
      v.valid?('0545290862').should be_false
    end

    it 'should not be valid for landline phones' do
      v.valid?('035447037').should be_false
      v.valid?('97235447037').should be_false
    end

    it 'should not be valid with country code but of different lenth' do
      v.valid?('9725452908622').should be_false
      v.valid?('97254529086').should be_false
    end

    it 'should be valid with country code' do
      v.valid?('972545290862').should be_true
    end
  end

end
