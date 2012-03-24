%w{config  gateway  sender  delivery_notifications_parser  report_puller  sms_reply  sms_replies_parser}.each do |file_name|
  require File.join(File.dirname(__FILE__), 'smsim', file_name)
end

%w{gateway_error}.each do |file_name|
  require File.join(File.dirname(__FILE__), 'smsim', 'errors', file_name)
end

require File.join(File.dirname(__FILE__), 'smsim', 'core_ext', 'blank') unless Object.new.respond_to?(:blank)

module Smsim

end
