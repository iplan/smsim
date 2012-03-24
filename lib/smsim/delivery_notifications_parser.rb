require "savon"
require 'nokogiri'

module Smsim
  class DeliveryNotificationsParser

    # params will look something like the following:
    # { "SegmentsNumber"=>"1", "ProjectId"=>"3127", "Status"=>"2", "SenderNumber"=>"0545290862", "StatusDescription"=>"Delivered",
    #   "PhoneNumber"=>"0545290862", "RetriesNumber"=>"0", "OriginalMessage"=>"מה מצב?",
    #   "CustomerMessageId"=>"18825cc0-6a2d-11e1-903f-70cd60fffee5", "BillingCodeId"=>"1", "id"=>"", "Network"=>"054", "CustomerParam"=>"",
    #   "NotificationDate"=>"09/03/2012 23:16:04", "ActionType"=>"Content", "Price"=>"0.00"}
    def self.http_push(params)
      ['PhoneNumber', 'Status', 'CustomerMessageId', 'SegmentsNumber', 'NotificationDate'].each do |p|
        raise Smsim::Errors::GatewayError.new(301, "Missing http parameter #{p}. Parameters were: #{params.inspect}") if params[p].blank?
      end

      values = {
        :gateway_status => params['Status'],
        :phone => params['PhoneNumber'],
        :message_id => params['CustomerMessageId'],
        :parts_count => params['SegmentsNumber'],
        :completed_at => params['NotificationDate'],
        :reason_not_delivered => params['StatusDescription'],
      }

      parse_notification_values_hash(values)
    end

    def self.parse_notification_values_hash(values)
      begin
        values[:gateway_status] = Integer(values[:gateway_status])
        values[:delivered?] = gateway_status_delivered?(values[:gateway_status])
      rescue Exception => e
        raise Smsim::Errors::GatewayError.new(302, "Status could not be converted to integer. Status was: #{values[:gateway_status]}")
      end

      begin
        values[:parts_count] = Integer(values[:parts_count])
      rescue Exception => e
        raise Smsim::Errors::GatewayError.new(302, "SegmentsNumber could not be converted to integer. SegmentsNumber was: #{values[:parts_count]}")
      end

      begin
        values[:completed_at] = DateTime.strptime(values[:completed_at], '%d/%m/%Y %H:%M:%S')
      rescue Exception => e
        raise Smsim::Errors::GatewayError.new(302, "NotificationDate could not be converted to date. NotificationDate was: #{values[:completed_at]}")
      end

      OpenStruct.new(values)
    end

    def self.gateway_status_delivered?(gateway_status)
      gateway_status == 2
    end

  end
end
