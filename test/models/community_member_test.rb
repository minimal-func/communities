require "test_helper"

class CommunityMemberTest < ActiveSupport::TestCase
  test "banned? returns true when banned_at is set" do
    admin = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    community_member = community.community_members.create!(member: admin, role: "admin", banned_at: Time.current)

    assert community_member.banned?
  end

  test "banned? returns false when banned_at is nil" do
    admin = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    community_member = community.community_members.create!(member: admin, role: "admin")

    assert_not community_member.banned?
  end

  test "active scope excludes banned members" do
    admin = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    member = Member.create!(wallet_address: "0x2222222222222222222222222222222222222222")
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    community.community_members.create!(member: admin, role: "admin", banned_at: Time.current)
    community.community_members.create!(member: member, role: "member")

    assert_equal [member.id], CommunityMember.active.pluck(:member_id)
  end

  test "active scope excludes banned and pending members" do
    admin = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    member = Member.create!(wallet_address: "0x2222222222222222222222222222222222222222")
    pending = Member.create!(wallet_address: "0x3333333333333333333333333333333333333333")
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    community.community_members.create!(member: admin, role: "admin", banned_at: Time.current)
    community.community_members.create!(member: member, role: "member")
    community.community_members.create!(member: pending, role: "member", requested_at: Time.current)

    assert_equal [member.id], CommunityMember.active.pluck(:member_id)
  end

  test "pending scope includes only pending members" do
    admin = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    member = Member.create!(wallet_address: "0x2222222222222222222222222222222222222222")
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    community.community_members.create!(member: admin, role: "admin")
    community.community_members.create!(member: member, role: "member", requested_at: Time.current)

    assert_equal [member.id], CommunityMember.pending.pluck(:member_id)
  end

  test "pending? returns true only for pending requests" do
    admin = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    member = Member.create!(wallet_address: "0x2222222222222222222222222222222222222222")
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    community.community_members.create!(member: admin, role: "admin")
    pending_member = community.community_members.create!(member: member, role: "member", requested_at: Time.current)

    assert pending_member.pending?
    assert_not community.community_members.find_by(member: admin).pending?
  end

  test "banned scope includes only banned members" do
    admin = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    member = Member.create!(wallet_address: "0x2222222222222222222222222222222222222222")
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    community.community_members.create!(member: admin, role: "admin", banned_at: Time.current)
    community.community_members.create!(member: member, role: "member")

    assert_equal [admin.id], CommunityMember.banned.pluck(:member_id)
  end

  test "requires valid role" do
    admin = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    community_member = community.community_members.build(member: admin, role: "superadmin")

    assert_not community_member.valid?
    assert_includes community_member.errors[:role], "is not included in the list"
  end

  test "requires unique member per community" do
    admin = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    community.community_members.create!(member: admin, role: "admin")

    duplicate = community.community_members.build(member: admin, role: "member")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:member_id], "is already a member of this community"
  end
end
