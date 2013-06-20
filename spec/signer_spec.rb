require 'spec_helper'

include Rack

describe UrlAuth::Signer do
  let(:signer) { UrlAuth::Signer.new('my-secretive-secret') }

  describe 'signing and validating messages' do
    let(:message)          { 'HMAC is fun!!' }
    let(:tampered_message) { 'HMAC is fun!!!' }

    it 'signs a messages' do
      signature = signer.sign message
      signature.should have(40).characters

      signer.verify(message, signature).should be true
      signer.verify(tampered_message, signature).should be false
    end
  end

  describe 'signed urls' do
    let(:url)        { 'http://example.com:3000/path?token=1&query=sumething' }
    let(:signed_url) { signer.sign_url url }

    it 'appends signature' do
      signed_url.should match %r{&signature=\w{40}}
    end

    it 'keeps params' do
      signed_url.should include '?token=1&query=sumething'
    end

    it 'keeps port' do
      signed_url.should match %{^http://example.com:3000}
    end

    it 'verifies untampered url' do
      signer.verify_url(signed_url).should be true
    end

    it 'verifies false if url is tampered' do
      signer.verify_url(signed_url.sub(/\.com/, '.me')).should       be false
      signer.verify_url(signed_url.sub('path', 'other-path')).should be false
      signer.verify_url(signed_url.sub('1', '2')).should             be false
    end

    it 'raises error when url is unsigned while verifying url' do
      lambda do
        signer.verify_url 'http://example.com'
      end.should raise_error UrlAuth::Signer::MissingSignature
    end
  end
end