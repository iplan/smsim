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
      @status == 2
    end

    def not_delivered?
      @status == -2
    end

    def blocked?
      @status == -4
    end

    # params will look something like the following:
    # { "SegmentsNumber"=>"1", "ProjectId"=>"3127", "Status"=>"2", "SenderNumber"=>"0545290862", "StatusDescription"=>"Delivered",
    #   "PhoneNumber"=>"0545290862", "RetriesNumber"=>"0", "OriginalMessage"=>"מה מצב?",
    #   "CustomerMessageId"=>"18825cc0-6a2d-11e1-903f-70cd60fffee5", "BillingCodeId"=>"1", "id"=>"", "Network"=>"054", "CustomerParam"=>"",
    #   "NotificationDate"=>"09/03/2012 23:16:04", "ActionType"=>"Content", "Price"=>"0.00"}
    def self.parse_from_http_params(params)
      ['PhoneNumber', 'Status', 'CustomerMessageId', 'SegmentsNumber', 'NotificationDate'].each do |p|
        raise Smsim::Errors::DeliveryNotificationError.new(-1, "Missing http parameter #{p}. Parameters were: #{params.inspect}") if params[p].blank?
      end

      values = {
        :status => params['Status'],
        :phone => params['PhoneNumber'],
        :message_id => params['CustomerMessageId'],
        :parts_count => params['SegmentsNumber'],
        :completed_at => params['NotificationDate'],
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

      begin
        values[:completed_at] = DateTime.strptime(values[:completed_at], '%d/%m/%Y %H:%M:%S')
      rescue Exception => e
        values[:completed_at] = Time.now
      end

      DeliveryNotification.new(values)
    end
  end
end