require "test_helper"

class CommunityTest < ActiveSupport::TestCase
  test "normalizes slug" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "My Community", slug: "  My Community  ", created_by_member: member)

    assert_equal "my-community", community.slug
  end

  test "requires name" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.new(slug: "test", created_by_member: member)

    assert_not community.valid?
    assert_includes community.errors[:name], "can't be blank"
  end

  test "requires unique slug" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    Community.create!(name: "First", slug: "same", created_by_member: member)
    duplicate = Community.new(name: "Second", slug: "same", created_by_member: member)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "admin? returns true for community admins" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    community.community_members.create!(member: member, role: "admin")

    assert community.admin?(member)
  end

  test "admin? returns false for regular members" do
    admin = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    member = Member.create!(wallet_address: "0x2222222222222222222222222222222222222222")
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    community.community_members.create!(member: admin, role: "admin")
    community.community_members.create!(member: member, role: "member")

    assert_not community.admin?(member)
  end

  test "member? returns true for any community member" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    community.community_members.create!(member: member, role: "member")

    assert community.member?(member)
  end

  test "member? returns false for non-members" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    other = Member.create!(wallet_address: "0x2222222222222222222222222222222222222222")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)

    assert_not community.member?(other)
  end

  test "banned_member? returns true for banned members" do
    admin = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    member = Member.create!(wallet_address: "0x2222222222222222222222222222222222222222")
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    community.community_members.create!(member: member, role: "member", banned_at: Time.current)

    assert community.banned_member?(member)
  end

  test "banned_member? returns false for active members" do
    admin = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    member = Member.create!(wallet_address: "0x2222222222222222222222222222222222222222")
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    community.community_members.create!(member: member, role: "member")

    assert_not community.banned_member?(member)
  end

  test "banned_member? returns false for non-members" do
    admin = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    other = Member.create!(wallet_address: "0x2222222222222222222222222222222222222222")
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)

    assert_not community.banned_member?(other)
  end

  test "member? returns false for banned members" do
    admin = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    member = Member.create!(wallet_address: "0x2222222222222222222222222222222222222222")
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    community.community_members.create!(member: member, role: "member", banned_at: Time.current)

    assert_not community.member?(member)
  end

  test "admin? returns false for banned admins" do
    admin = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    member = Member.create!(wallet_address: "0x2222222222222222222222222222222222222222")
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    community.community_members.create!(member: member, role: "admin", banned_at: Time.current)

    assert_not community.admin?(member)
  end
end
