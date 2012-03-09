%w{error  gateway  gateway_error  http_error  http_executor  xml_request_builder  xml_response}.each do |file_name|
  require File.join(File.dirname(__FILE__), 'smsim', file_name)
end

require File.join(File.dirname(__FILE__), 'smsim', 'core_ext', 'blank') unless Object.new.respond_to?(:blank)

module Smsim

end
