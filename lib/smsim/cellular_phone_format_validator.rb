module Smsim
  class CellularPhoneFormatValidator
    @@valid_full_length = '972545123456'.length

    # validates that given phone is Israely celluar format with country code: 972545123456
    def self.valid?(phone, errors = [])
      if phone.is_a?(String)
        errors << "Must start with 972" unless phone.start_with?('972')
        errors << "Must start consist of #{@@valid_full_length} digits (like 972545123456)" unless phone =~ /^#{972}[0-9]{#{@@valid_full_length-3}}$/
      else
        errors << 'Must be a string of 12 characters starting with 972 country code'
      end
      errors.empty?
    end
  end
end