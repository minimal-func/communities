require "test_helper"

class WaitlistEntryTest < ActiveSupport::TestCase
  test "normalizes wallet address" do
    entry = WaitlistEntry.create!(
      wallet_address: "  0xABCDEFabcdefABCDEFabcdefABCDEFabcdefABCD  ",
      community_name: "Greenhaven Commons"
    )

    assert_equal "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd", entry.wallet_address
  end

  test "defaults to pending status" do
    entry = WaitlistEntry.create!(
      wallet_address: "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      community_name: "Greenhaven Commons"
    )

    assert_predicate entry, :pending?
  end

  test "requires unique wallet address" do
    WaitlistEntry.create!(wallet_address: "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", community_name: "Greenhaven Commons")
    duplicate = WaitlistEntry.new(wallet_address: "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:wallet_address], "has already been taken"
  end

  test "requires a community name" do
    entry = WaitlistEntry.new(wallet_address: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee")

    assert_not entry.valid?
    assert_includes entry.errors[:community_name], "can't be blank"
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
    entry = WaitlistEntry.create!(wallet_address: "0xcccccccccccccccccccccccccccccccccccccccc", community_name: "Greenhaven Commons")

    freeze_time do
      entry.approve!(admin)

      assert_predicate entry, :approved?
      assert_equal admin, entry.approved_by_admin_user
      assert_equal Time.current, entry.approved_at
    end
  end

  test "reject! marks entry as rejected" do
    admin = admin_users(:one)
    entry = WaitlistEntry.create!(wallet_address: "0xcccccccccccccccccccccccccccccccccccccccc", community_name: "Greenhaven Commons")

    freeze_time do
      entry.reject!(admin)

      assert_predicate entry, :rejected?
      assert_equal admin, entry.approved_by_admin_user
      assert_equal Time.current, entry.rejected_at
    end
  end

  test "accept! marks entry as accepted by member" do
    entry = WaitlistEntry.create!(
      wallet_address: "0xdddddddddddddddddddddddddddddddddddddddd",
      community_name: "Greenhaven Commons",
      community_description: "A solarpunk neighborhood."
    )
    member = Member.create!(wallet_address: entry.wallet_address)

    freeze_time do
      entry.accept!(member)

      assert_predicate entry, :accepted?
      assert_equal member, entry.accepted_member
      assert_equal Time.current, entry.accepted_at
    end
  end

  test "accept! founds the proposed community and makes the member its first admin" do
    entry = WaitlistEntry.create!(
      wallet_address: "0xdddddddddddddddddddddddddddddddddddddddd",
      community_name: "Greenhaven Commons",
      community_description: "A solarpunk neighborhood."
    )
    member = Member.create!(wallet_address: entry.wallet_address)

    entry.accept!(member)

    community = entry.community
    assert_not_nil community
    assert_equal "Greenhaven Commons", community.name
    assert_equal "A solarpunk neighborhood.", community.description
    assert_equal member, community.created_by_member
    membership = community.community_members.find_by(member: member)
    assert_equal "admin", membership.role
  end

  test "accept! creates a unique slug when a community name is taken" do
    Community.create!(name: "Greenhaven Commons", slug: "greenhaven-commons", created_by_member: Member.create!(wallet_address: "0xffffffffffffffffffffffffffffffffffffffff"))
    entry = WaitlistEntry.create!(wallet_address: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", community_name: "Greenhaven Commons")
    member = Member.create!(wallet_address: entry.wallet_address)

    entry.accept!(member)

    assert_equal "greenhaven-commons-2", entry.community.slug
  end
end
