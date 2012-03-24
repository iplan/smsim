require 'spec_helper'

describe Smsim::SmsRepliesParser do
  let(:parser) { Smsim::SmsRepliesParser }

  describe '#http_push' do
    let(:reply_values) { {'PhoneNumber' => '0541234567', 'Message' => 'kak dila', 'ShortCode' => '0529992090'} }
    let(:reply) { parser.http_push({'IncomingXML' => XmlResponseStubs.sms_reply_http_xml_string(reply_values)}) }

    it 'should raise DeliveryNotificationError if parameters are missing or not of expected type' do
      lambda { parser.http_push({'Puki' => 'asdf'}) }.should raise_error(Smsim::Errors::GatewayError)
    end

    it 'should return SmsReply with all fields initialized' do
      Time.stub(:now).and_return(Time.utc(2011, 8, 1, 11, 15, 00))

      reply.should be_present
      reply.phone.should == '0541234567'
      reply.text.should == 'kak dila'
      reply.replied_to.should == '0529992090'
      reply.received_at.strftime('%d/%m/%Y %H:%M:%S').should == '01/08/2011 11:15:00'
    end
  end

end
