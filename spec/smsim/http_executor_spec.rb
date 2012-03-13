require 'spec_helper'

describe Smsim::HttpExecutor do
  let(:request_uri){ Smsim::Gateway.urls.send_sms }

  describe '#verify_response_code' do
    let(:executor){ Smsim::HttpExecutor }
    it 'should raise HttpResponseError if url not found' do
      stub_request(:any, request_uri).to_return(:status => 404)
      lambda{ executor.verify_response_code(executor.post(request_uri, :body => 'asdf')) }.should raise_error(Smsim::Errors::HttpResponseError)
    end

    it 'should not raise error url if response code is ok (200 http status)' do
      stub_request(:any, request_uri).to_return(:status => 200, :body => 'response body')
      executor.verify_response_code(executor.get(request_uri)).should be_true
    end
  end

  describe '#send_sms' do

  end

end
