%w{gateway_urls  gateway  http_executor  xml_request_builder  xml_response_parser  delivery_notification  delivery_notifications_parser}.each do |file_name|
  require File.join(File.dirname(__FILE__), 'smsim', file_name)
end

%w{error  gateway_error  http_response_error  xml_response_error  delivery_notification_error}.each do |file_name|
  require File.join(File.dirname(__FILE__), 'smsim', 'errors', file_name)
end

require File.join(File.dirname(__FILE__), 'smsim', 'core_ext', 'blank') unless Object.new.respond_to?(:blank)

module Smsim

end
