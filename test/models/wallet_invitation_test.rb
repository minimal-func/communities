require "test_helper"

class WalletInvitationTest < ActiveSupport::TestCase
  test "normalizes wallet address" do
    inviter = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    invitation = WalletInvitation.create!(
      wallet_address: "  0xABCDEFabcdefABCDEFabcdefABCDEFabcdefABCD  ",
      invited_by_member: inviter
    )

    assert_equal "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd", invitation.wallet_address
  end

  test "requires unique wallet address per community" do
    inviter = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    WalletInvitation.create!(wallet_address: "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", invited_by_member: inviter)
    duplicate = WalletInvitation.new(wallet_address: "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", invited_by_member: inviter)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:wallet_address], "already invited to this community"
  end

  test "allows same wallet address for different communities" do
    inviter = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community_a = Community.create!(name: "A", slug: "a", created_by_member: inviter)
    community_b = Community.create!(name: "B", slug: "b", created_by_member: inviter)
    WalletInvitation.create!(wallet_address: "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", invited_by_member: inviter, community: community_a)
    duplicate = WalletInvitation.new(wallet_address: "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", invited_by_member: inviter, community: community_b)

    assert duplicate.valid?
  end

  test "rejects wallet address belonging to existing member" do
    Member.create!(wallet_address: "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
    inviter = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    invitation = WalletInvitation.new(wallet_address: "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", invited_by_member: inviter)

    assert_not invitation.valid?
    assert_includes invitation.errors[:wallet_address], "already belongs to a member"
  end

  test "rejects invalid ethereum address" do
    inviter = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    invitation = WalletInvitation.new(wallet_address: "not-a-wallet", invited_by_member: inviter)

    assert_not invitation.valid?
    assert_includes invitation.errors[:wallet_address], "must be an Ethereum address"
  end

  test "pending scope returns only unaccepted invitations" do
    inviter = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    pending = WalletInvitation.create!(wallet_address: "0xcccccccccccccccccccccccccccccccccccccccc", invited_by_member: inviter)
    accepted = WalletInvitation.create!(wallet_address: "0xdddddddddddddddddddddddddddddddddddddddd", invited_by_member: inviter)
    accepted.update!(accepted_at: Time.current, accepted_member: inviter)

    assert_includes WalletInvitation.pending, pending
    assert_not_includes WalletInvitation.pending, accepted
  end

  test "accept! marks invitation as accepted" do
    inviter = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    invitee_wallet = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
    invitation = WalletInvitation.create!(wallet_address: invitee_wallet, invited_by_member: inviter)
    invitee = Member.create!(wallet_address: invitee_wallet)

    freeze_time do
      invitation.accept!(invitee)

      assert_equal invitee, invitation.accepted_member
      assert_equal Time.current, invitation.accepted_at
    end
  end

  test "accept! creates community member when community is set" do
    inviter = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: inviter)
    invitee_wallet = "0xffffffffffffffffffffffffffffffffffffffff"
    invitation = WalletInvitation.create!(
      wallet_address: invitee_wallet,
      invited_by_member: inviter,
      community: community,
      community_role: "admin"
    )
    invitee = Member.create!(wallet_address: invitee_wallet)

    assert_difference "community.community_members.count", 1 do
      invitation.accept!(invitee)
    end

    cm = community.community_members.last
    assert_equal invitee, cm.member
    assert_equal "admin", cm.role
  end

  test "accept! does not create community member when community is not set" do
    inviter = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    invitee_wallet = "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    invitation = WalletInvitation.create!(wallet_address: invitee_wallet, invited_by_member: inviter)
    invitee = Member.create!(wallet_address: invitee_wallet)

    assert_no_difference "CommunityMember.count" do
      invitation.accept!(invitee)
    end
  end
end
