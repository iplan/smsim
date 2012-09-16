require 'active_support/all'

%w{gateway  gateway_error   sms_sender  delivery_notifications_parser  report_puller  sms_replies_parser  phone_number_utils}.each do |file_name|
  require File.join(File.dirname(__FILE__), 'smsim', file_name)
end

module Smsim

end
