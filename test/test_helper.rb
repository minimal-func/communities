ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "digest/keccak"
require "ecdsa"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def ethereum_private_key
      1 + SecureRandom.random_number(ECDSA::Group::Secp256k1.order - 1)
    end

    def ethereum_address(private_key)
      public_key = ECDSA::Group::Secp256k1.generator.multiply_by_scalar(private_key)
      public_key_hex = public_key.x.to_s(16).rjust(64, "0") + public_key.y.to_s(16).rjust(64, "0")
      "0x#{::Digest::Keccak.hexdigest([ public_key_hex ].pack("H*"), 256).last(40)}"
    end

    def personal_sign(private_key, message)
      prefixed = "\x19Ethereum Signed Message:\n#{message.bytesize}#{message}"
      digest = ::Digest::Keccak.digest(prefixed, 256)
      signature = nil

      signature ||= ECDSA.sign(
        ECDSA::Group::Secp256k1,
        private_key,
        digest,
        1 + SecureRandom.random_number(ECDSA::Group::Secp256k1.order - 1)
      )

      "0x#{signature.r.to_s(16).rjust(64, "0")}#{signature.s.to_s(16).rjust(64, "0")}1b"
    end
  end
end
