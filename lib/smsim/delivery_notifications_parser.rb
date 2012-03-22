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


    #<ClientNotification><Status>OK</Status><BatchSize>1</BatchSize><Messages><Message><Type>Notification</Type><PhoneNumber>0527718999</PhoneNumber><Network>052</Network><Status>2</Status><StatusDescription>Delivered</StatusDescription><CustomerMessageId></CustomerMessageId><CustomerParam></CustomerParam><SenderNumber>0545290862</SenderNumber><SegmentsNumber>1</SegmentsNumber><NotificationDate>13/03/2012 10:16:56</NotificationDate><SentMessage>test</SentMessage></Message></Messages></ClientNotification>
    #<ClientNotification><Status>OK</Status><BatchSize>0</BatchSize></ClientNotification>
    def self.delivery_report_pull(username, password, batch_size = 100)
      service = Savon::Client.new(Smsim::Gateway.urls.delivery_report_pull)
      response = service.request 'PullClientNotification' do
        soap.body = {'userName' => username, 'password' => password, 'batchSize' => batch_size}
      end
      xml = response.doc
      xml.remove_namespaces!

      # temporary convert hash, remove when new version is uploaded (talk to Zorik about it)
      mapper_status_text_to_integer = {'OK' => 1, 'Failed' => -1, 'BadUserNameOrPassword' => -2, 'UserNameNotExists' => -3, 'PasswordNotExists' => -4}
      response_status = xml.at_css('Status').text
      raise Smsim::Errors::DeliveryNotificationError.new(100, "Response status '#{response_status}' is neither of #{mapper_status_text_to_integer.keys}") unless mapper_status_text_to_integer.keys.include?(response_status)

      begin
        batch_size = Integer(xml.at_css('BatchSize').text)
      rescue Exception => e
        raise Smsim::Errors::DeliveryNotificationError.new(100, e.message)
      end

      response = OpenStruct.new({
        :status => mapper_status_text_to_integer[response_status],
        :batch_size => batch_size,
        :messages => [],
        :errors => []
      })

      if response.status == 1 && response.batch_size > 0 # parse notifications
        xml.css('Messages Message').each do |msg|
          begin
            response.messages << DeliveryNotification.new(
              :status => Integer(msg.at_css('Status').text),
              :parts_count => Integer(msg.at_css('SegmentsNumber').text),
              :message_id => msg.at_css('CustomerMessageId').text,
              :phone => msg.at_css('PhoneNumber').text,
              :reason_not_delivered => msg.at_css('StatusDescription').text,
              :completed_at => DateTime.strptime(msg.at_css('NotificationDate').text, '%d/%m/%Y %H:%M:%S')
            )
          rescue Exception => e
            response.errors << {:xml => msg.to_xml, :error => e.message}
          end
        end
      end

      response
    end

  end
end
