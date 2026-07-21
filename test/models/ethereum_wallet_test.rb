require "test_helper"

class EthereumWalletTest < ActiveSupport::TestCase
  test "normalize strips whitespace and lowercases" do
    assert_equal "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd",
      EthereumWallet.normalize("  0xABCDEFabcdefABCDEFabcdefABCDEFabcdefABCD  ")
  end

  test "normalize handles nil input" do
    assert_equal "", EthereumWallet.normalize(nil)
  end

  test "valid_address? accepts correct format" do
    assert EthereumWallet.valid_address?("0x1234567890abcdef1234567890abcdef12345678")
  end

  test "valid_address? rejects missing 0x prefix" do
    assert_not EthereumWallet.valid_address?("1234567890abcdef1234567890abcdef12345678")
  end

  test "valid_address? rejects short address" do
    assert_not EthereumWallet.valid_address?("0x1234")
  end

  test "valid_address? rejects non-hex characters" do
    assert_not EthereumWallet.valid_address?("0xgggggggggggggggggggggggggggggggggggggggg")
  end

  test "valid_address? rejects nil" do
    assert_not EthereumWallet.valid_address?(nil)
  end
end
