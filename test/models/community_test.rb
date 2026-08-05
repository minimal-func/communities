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

  test "defaults to closed visibility" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)

    assert_equal "closed", community.visibility
    assert community.closed?
    assert_not community.open?
    assert_not community.secret?
  end

  test "validates visibility" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.new(name: "Test", slug: "test", created_by_member: member, visibility: "public")

    assert_not community.valid?
    assert_includes community.errors[:visibility], "is not included in the list"
  end

  test "visible_to_member excludes secret communities for non-members" do
    admin = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    member = Member.create!(wallet_address: "0x2222222222222222222222222222222222222222")
    open = Community.create!(name: "Open", slug: "open", created_by_member: admin, visibility: "open")
    closed = Community.create!(name: "Closed", slug: "closed", created_by_member: admin, visibility: "closed")
    secret = Community.create!(name: "Secret", slug: "secret", created_by_member: admin, visibility: "secret")
    secret.community_members.create!(member: admin, role: "admin")

    assert_equal [open, closed].sort_by(&:id), Community.visible_to_member(member).sort_by(&:id)
    assert_equal [open, closed, secret].sort_by(&:id), Community.visible_to_member(admin).sort_by(&:id)
  end

  test "visible_to_member includes secret communities for their members" do
    admin = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    member = Member.create!(wallet_address: "0x2222222222222222222222222222222222222222")
    secret = Community.create!(name: "Secret", slug: "secret", created_by_member: admin, visibility: "secret")
    secret.community_members.create!(member: member, role: "member")

    assert_includes Community.visible_to_member(member), secret
  end

  test "visible_to? returns true for open and closed communities for any member" do
    admin = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    other = Member.create!(wallet_address: "0x2222222222222222222222222222222222222222")
    open = Community.create!(name: "Open", slug: "open", created_by_member: admin, visibility: "open")
    closed = Community.create!(name: "Closed", slug: "closed", created_by_member: admin, visibility: "closed")
    secret = Community.create!(name: "Secret", slug: "secret", created_by_member: admin, visibility: "secret")

    assert open.visible_to?(other)
    assert closed.visible_to?(other)
    assert_not secret.visible_to?(other)
  end

  test "content_visible_to? is members-only for closed and secret communities" do
    admin = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    member = Member.create!(wallet_address: "0x2222222222222222222222222222222222222222")
    open = Community.create!(name: "Open", slug: "open", created_by_member: admin, visibility: "open")
    closed = Community.create!(name: "Closed", slug: "closed", created_by_member: admin, visibility: "closed")
    closed.community_members.create!(member: member, role: "member")

    assert open.content_visible_to?(member)
    assert closed.content_visible_to?(member)
    assert_not closed.content_visible_to?(admin)
  end

  test "pending_member? returns true only for pending membership requests" do
    admin = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    pending = Member.create!(wallet_address: "0x2222222222222222222222222222222222222222")
    active = Member.create!(wallet_address: "0x3333333333333333333333333333333333333333")
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin, visibility: "closed")
    community.community_members.create!(member: pending, role: "member", requested_at: Time.current)
    community.community_members.create!(member: active, role: "member")

    assert community.pending_member?(pending)
    assert_not community.pending_member?(active)
    assert_not community.pending_member?(admin)
  end
end
