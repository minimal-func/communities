require "digest/keccak"
require "ecdsa"

class EthereumSignatureVerifier
  GROUP = ECDSA::Group::Secp256k1

  def self.valid_personal_signature?(wallet_address:, message:, signature:)
    new(wallet_address, message, signature).valid_personal_signature?
  end

  def initialize(wallet_address, message, signature)
    @wallet_address = EthereumWallet.normalize(wallet_address)
    @message = message.to_s
    @signature = signature.to_s
  end

  def valid_personal_signature?
    return false unless EthereumWallet.valid_address?(wallet_address)

    parsed_signature => { r:, s: }
    digest = ethereum_signed_message_digest(message)
    signature = ECDSA::Signature.new(r, s)

    ECDSA.recover_public_key(GROUP, digest, signature).any? do |public_key|
      public_key_to_address(public_key) == wallet_address
    end
  rescue ECDSA::Format::DecodeError, ArgumentError
    false
  end

  private

  attr_reader :wallet_address, :message, :signature

  def parsed_signature
    hex = signature.delete_prefix("0x")
    raise ArgumentError, "signature must be 65 bytes" unless hex.match?(/\A[0-9a-fA-F]{130}\z/)

    {
      r: hex[0, 64].to_i(16),
      s: hex[64, 64].to_i(16),
      v: hex[128, 2].to_i(16)
    }
  end

  def ethereum_signed_message_digest(payload)
    prefixed = "\x19Ethereum Signed Message:\n#{payload.bytesize}#{payload}"
    Digest::Keccak.digest(prefixed, 256)
  end

  def public_key_to_address(public_key)
    public_key_hex = public_key.x.to_s(16).rjust(64, "0") + public_key.y.to_s(16).rjust(64, "0")
    "0x#{Digest::Keccak.hexdigest([ public_key_hex ].pack("H*"), 256).last(40)}"
  end
end
