require 'spec_helper'

describe Smsim::SmsRepliesParser do
  let(:gateway){ Smsim::Gateway.new(:username => 'alex', :password => 'pass') }
  let(:parser){ gateway.sms_replies_parser }

  describe '#http_push' do
    let(:reply_values) { {'PhoneNumber' => '0541234567', 'Message' => 'kak dila', 'ShortCode' => '0529992090'} }
    let(:reply) { parser.http_push({'IncomingXML' => XmlResponseStubs.sms_reply_http_xml_string(reply_values)}) }

    it 'should raise DeliveryNotificationError if parameters are missing or not of expected type' do
      lambda { parser.http_push({'Puki' => 'asdf'}) }.should raise_error(Smsim::GatewayError)
    end

    it 'should return SmsReply with all fields initialized' do
      Time.stub(:now).and_return(Time.utc(2011, 8, 1, 11, 15, 00))

      reply.should be_present
      reply.phone.should == '972541234567'
      reply.text.should == 'kak dila'
      reply.reply_to_phone.should == '972529992090'
      reply.received_at.strftime('%d/%m/%Y %H:%M:%S').should == '01/08/2011 11:15:00'
    end
  end

  describe '#generate_reply_message_id' do
    it 'should convert from phone number that contains only digits to integer and then to 36 base' do
      parser.generate_reply_message_id('0541234567', '1234', Time.now).split('-').first.should == '8y8j9j'
      parser.generate_reply_message_id('972541234567', '1234', Time.now).split('-').first.should == 'ces1xv9j'
    end

    it 'should not modify phone number that contains non digits' do
      parser.generate_reply_message_id('+054123a4567', '123', Time.now).split('-').first.should == '+054123a4567'
      parser.generate_reply_message_id('+9725412a34567', '123', Time.now).split('-').first.should == '+9725412a34567'
    end

    it 'should convert reply to phone number that contains only digits to integer and then to 36 base' do
      parser.generate_reply_message_id('1234', '0541234567', Time.now).split('-').second.should == '8y8j9j'
      parser.generate_reply_message_id('1234', '972541234567', Time.now).split('-').second.should == 'ces1xv9j'
    end

    it 'should not modify reply to phone number that contains non digits' do
      parser.generate_reply_message_id('1234', '+054123a4567', Time.now).split('-').second.should == '+054123a4567'
      parser.generate_reply_message_id('1234', '+972541234567', Time.now).split('-').second.should == '+972541234567'
    end
  end

end
