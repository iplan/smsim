require "savon"
require 'nokogiri'

module Smsim
  class SmsRepliesParser


    # params will look something like the following:
    # { "IncomingXML" => "<IncomingData>
    #                      <PhoneNumber>0501111111</PhoneNumber>
    #                      <Keyword>Hello</Keyword>
    #                      <Message>Hello Word</Message>
    #                      <Network>052</Network>
    #                      <ShortCode>5454</ShortCode>
    #                      <CustomerID>12</CustomerID>
    #                      <ProjectID>123</ProjectID>
    #                      <ApplicationID>12321</ApplicationID>
    #                    </IncomingData>" }
    # PhoneNumber - the number of person who replied to sms
    # Message - text of the message
    # ShortCode - number to which reply was sent (0529992090)
    def self.http_push(params)
      ['IncomingXML'].each do |p|
        raise Smsim::Errors::SmsReplyError.new(-1, "Missing http parameter #{p}. Parameters were: #{params.inspect}") if params[p].blank?
      end

      begin
        doc = ::Nokogiri::XML(params['IncomingXML'])
        values = {
          :phone => doc.at_css('IncomingData PhoneNumber').text,
          :text => doc.at_css('IncomingData Message').text,
          :replied_to => doc.at_css('IncomingData ShortCode').text,
          :received_at => Time.now
        }
      rescue Exception => e
        raise Smsim::Errors::SmsReplyError.new(100, e.message)
      end

      SmsReply.new(values)
    end


  end
end
