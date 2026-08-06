require "test_helper"

class WaitlistEntryTest < ActiveSupport::TestCase
  test "normalizes wallet address" do
    entry = WaitlistEntry.create!(
      wallet_address: "  0xABCDEFabcdefABCDEFabcdefABCDEFabcdefABCD  "
    )

    assert_equal "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd", entry.wallet_address
  end

  test "defaults to pending status" do
    entry = WaitlistEntry.create!(wallet_address: "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")

    assert_predicate entry, :pending?
  end

  test "requires unique wallet address" do
    WaitlistEntry.create!(wallet_address: "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    duplicate = WaitlistEntry.new(wallet_address: "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:wallet_address], "has already been taken"
  end

  test "rejects invalid ethereum address" do
    entry = WaitlistEntry.new(wallet_address: "not-a-wallet")

    assert_not entry.valid?
    assert_includes entry.errors[:wallet_address], "must be an Ethereum address"
  end

  test "rejects wallet address belonging to existing member" do
    Member.create!(wallet_address: "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
    entry = WaitlistEntry.new(wallet_address: "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")

    assert_not entry.valid?
    assert_includes entry.errors[:wallet_address], "already belongs to a member"
  end

  test "approve! marks entry as approved by admin" do
    admin = admin_users(:one)
    entry = WaitlistEntry.create!(wallet_address: "0xcccccccccccccccccccccccccccccccccccccccc")

    freeze_time do
      entry.approve!(admin)

      assert_predicate entry, :approved?
      assert_equal admin, entry.approved_by_admin_user
      assert_equal Time.current, entry.approved_at
    end
  end

  test "reject! marks entry as rejected" do
    admin = admin_users(:one)
    entry = WaitlistEntry.create!(wallet_address: "0xcccccccccccccccccccccccccccccccccccccccc")

    freeze_time do
      entry.reject!(admin)

      assert_predicate entry, :rejected?
      assert_equal admin, entry.approved_by_admin_user
      assert_equal Time.current, entry.rejected_at
    end
  end

  test "accept! marks entry as accepted by member" do
    entry = WaitlistEntry.create!(wallet_address: "0xdddddddddddddddddddddddddddddddddddddddd")
    member = Member.create!(wallet_address: entry.wallet_address)

    freeze_time do
      entry.accept!(member)

      assert_predicate entry, :accepted?
      assert_equal member, entry.accepted_member
      assert_equal Time.current, entry.accepted_at
    end
  end
end
