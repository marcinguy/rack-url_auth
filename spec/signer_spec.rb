require 'spec_helper'

include Rack

describe UrlAuth::Signer do
  let(:signer) { UrlAuth::Signer.new('my-secretive-secret') }

  describe 'signing and validating messages' do
    let(:message)          { 'HMAC is fun!!' }
    let(:tampered_message) { 'HMAC is fun!!!' }
    let(:signature)        { signer.sign message }

    it 'signs a messages' do
      expect(signature.size).to eq(64)
      expect(signer.verify(message, signature)).to be true
      expect(signer.verify(tampered_message, signature)).to be false
    end
  end

  describe 'signed urls' do
    let(:url)        { 'http://example.com/path?token=1&query=sumething' }
    let(:signed_url) { signer.sign_url url }

    it 'appends signature' do
      expect(signed_url).to match %r{&signature=\w{40}}
    end

    it 'keeps params' do
      expect(signed_url).to include '?token=1&query=sumething'
    end

    it 'keeps host and path' do
      expect(signed_url).to match %r{http://example\.com/path}
    end

    it 'obviates port if 443' do
      signed_url = signer.sign_url 'http://example.com:443/path?token=1&query=sumething'
      expect(signed_url).to match %{^http://example.com/path}
    end

    it 'keeps port if different than 80' do
      signed_url = signer.sign_url 'http://example.com:3000/path?token=1&query=sumething'
      expect(signed_url).to match %{^http://example.com:3000}
    end

    it 'raises error if scheme is not provided' do
      expect {
        signer.sign_url 'example.com'
      }.to raise_error ArgumentError
    end

    it 'verifies untampered url' do
      expect(signer.verify_url(signed_url)).to be true
    end

    it 'verifies false if url is tampered' do
      expect(signer.verify_url(signed_url.sub(/\.com/, '.me'))).to       be false
      expect(signer.verify_url(signed_url.sub('path', 'other-path'))).to be false
      expect(signer.verify_url(signed_url.sub('1', '2'))).to             be false
    end

    it 'raises error when url is unsigned while verifying url' do
      expect {
        signer.verify_url 'http://example.com'
      }.to raise_error UrlAuth::Signer::MissingSignature
    end
  end
end
