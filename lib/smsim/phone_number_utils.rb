module Smsim

  class PhoneNumberUtils

    # this method adds 972 country code to given phone if needed
    # if phone is blank --> doesn't change it
    def self.ensure_country_code(phone)
      if !phone.blank? && !phone.start_with?('972')
        phone = phone[1..phone.size] if phone.start_with?('0')
        phone = "972#{phone}"
      end
      phone
    end

    @@valid_full_length = '972545123456'.length
    # validates that given phone is Israeli cellular format with country code: 972545123456
    def self.valid_cellular_phone?(phone, errors = [])
      phone = phone.to_s
      errors << "Must start with 972" unless phone.start_with?('972')
      errors << "Must start consist of #{@@valid_full_length} digits (like 972545123456)" unless phone =~ /^#{972}[0-9]{#{@@valid_full_length-3}}$/
      errors.empty?
    end

  end

end