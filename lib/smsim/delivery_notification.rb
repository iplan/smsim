module Smsim
  class DeliveryNotification
    def initialize(values)
      @values = values
    end

    def status
      @values[:status]
    end

    def message_id
      @values[:message_id]
    end

    def phone
      @values[:phone]
    end

    def parts_count
      @values[:parts_count]
    end

    def completed_at
      @values[:completed_at]
    end

    def reason_not_delivered
      @values[:reason_not_delivered]
    end

    def delivered?
      status == 2
    end

    def not_delivered?
      status == -2
    end

    def blocked?
      status == -4
    end

  end
end
