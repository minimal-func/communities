require "test_helper"

class MemberTest < ActiveSupport::TestCase
  test "normalizes ethereum wallet addresses" do
    member = Member.create!(wallet_address: "  0xABCDEFabcdefABCDEFabcdefABCDEFabcdefABCD  ")

    assert_equal "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd", member.wallet_address
  end

  test "rejects invalid wallet addresses" do
    member = Member.new(wallet_address: "not-a-wallet")

    assert_not member.valid?
    assert_includes member.errors[:wallet_address], "must be an Ethereum address"
  end
end
