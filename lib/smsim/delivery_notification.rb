module Smsim
  class DeliveryNotification
    attr_reader :status

    def initialize(values)
      @values = values
      @status = values[:status]
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
      @status == 2
    end

    def not_delivered?
      @status == -2
    end

    def blocked?
      @status == -4
    end

    def self.parse_from_http_params(params)
      ['PhoneNumber', 'Status', 'CustomerMessageId', 'SegmentsNumber'].each do |p|
        raise Smsim::Errors::DeliveryNotificationError.new(-1, "Missing http parameter #{p}. Parameters were: #{params.inspect}") if params[p].blank?
      end

      values = {
        :status => params['Status'],
        :phone => params['PhoneNumber'],
        :message_id => params['CustomerMessageId'],
        :parts_count => params['SegmentsNumber'],
        :completed_at => Time.now,
        :reason_not_delivered => params['StatusDescription'],
      }

      begin
        values[:status] = Integer(values[:status])
      rescue Exception => e
        raise Smsim::Errors::DeliveryNotificationError.new(-2, "Status could not be converted to integer. Status was: #{values[:status]}")
      end

      begin
        values[:parts_count] = Integer(values[:parts_count])
      rescue Exception => e
        raise Smsim::Errors::DeliveryNotificationError.new(-2, "SegmentsNumber could not be converted to integer. SegmentsNumber was: #{values[:parts_count]}")
      end

      DeliveryNotification.new(values)
    end
  end
end