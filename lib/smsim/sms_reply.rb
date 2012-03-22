module Smsim
  class SmsReply
    def initialize(values)
      @values = values
    end
    
    def text
      @values[:text]
    end

    def phone
      @values[:phone]
    end

    def replied_to
      @values[:replied_to]
    end

    def received_at
      @values[:received_at]
    end
  end
end
