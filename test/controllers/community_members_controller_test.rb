require "test_helper"

class CommunityMembersControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    member = Member.create!(wallet_address: ethereum_address(ethereum_private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)

    post community_members_path(community), params: { wallet_address: "0x1111111111111111111111111111111111111111" }

    assert_redirected_to login_path
  end

  test "requires community admin role" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    community.community_members.create!(member: admin, role: "admin")

    member_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(member_key))

    sign_in_with_wallet(member, member_key)

    post community_members_path(community), params: { wallet_address: "0x2222222222222222222222222222222222222222" }

    assert_redirected_to community_path(community)
  end

  test "adds an existing member to the community" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    community.community_members.create!(member: admin, role: "admin")

    member_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(member_key))

    sign_in_with_wallet(admin, admin_key)

    assert_difference "community.community_members.count", 1 do
      post community_members_path(community), params: { wallet_address: member.wallet_address }
    end

    assert_redirected_to community_members_path(community)
    assert_equal "Member added.", flash[:notice]
    assert_equal "member", community.community_members.last.role
  end

  test "adds an existing member as admin" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    community.community_members.create!(member: admin, role: "admin")

    member_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(member_key))

    sign_in_with_wallet(admin, admin_key)

    assert_difference "community.community_members.count", 1 do
      post community_members_path(community), params: { wallet_address: member.wallet_address, role: "admin" }
    end

    assert_redirected_to community_members_path(community)
    assert_equal "admin", community.community_members.last.role
  end

  test "does not add a member already in the community" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    community.community_members.create!(member: admin, role: "admin")

    sign_in_with_wallet(admin, admin_key)

    post community_members_path(community), params: { wallet_address: admin.wallet_address }

    assert_response :unprocessable_entity
    assert_select ".alert", /already part/
  end

  test "invites a non-existent wallet to the system" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    community.community_members.create!(member: admin, role: "admin")

    new_address = "0x1111111111111111111111111111111111111111"

    sign_in_with_wallet(admin, admin_key)

    assert_difference "WalletInvitation.count", 1 do
      post community_members_path(community), params: { wallet_address: new_address }
    end

    assert_redirected_to community_members_path(community)
    assert_equal "Invitation sent to #{new_address.downcase}.", flash[:notice]

    invitation = WalletInvitation.last
    assert_equal new_address.downcase, invitation.wallet_address
    assert_equal admin, invitation.invited_by_member
    assert_equal community, invitation.community
    assert_equal "member", invitation.community_role
    assert_nil invitation.accepted_at
  end

  test "invites a non-existent wallet as admin" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    community.community_members.create!(member: admin, role: "admin")

    new_address = "0x3333333333333333333333333333333333333333"

    sign_in_with_wallet(admin, admin_key)

    assert_difference "WalletInvitation.count", 1 do
      post community_members_path(community), params: { wallet_address: new_address, role: "admin" }
    end

    invitation = WalletInvitation.last
    assert_equal "admin", invitation.community_role
  end

  test "shows error when wallet is already invited to the same community" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    community.community_members.create!(member: admin, role: "admin")

    sign_in_with_wallet(admin, admin_key)

    WalletInvitation.create!(wallet_address: "0x2222222222222222222222222222222222222222", invited_by_member: admin, community: community)

    post community_members_path(community), params: { wallet_address: "0x2222222222222222222222222222222222222222" }

    assert_response :unprocessable_entity
  end

  test "invites same wallet to a different community" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key))
    community_a = Community.create!(name: "A", slug: "a", created_by_member: admin)
    community_b = Community.create!(name: "B", slug: "b", created_by_member: admin)
    community_a.community_members.create!(member: admin, role: "admin")
    community_b.community_members.create!(member: admin, role: "admin")

    wallet = "0x4444444444444444444444444444444444444444"
    WalletInvitation.create!(wallet_address: wallet, invited_by_member: admin, community: community_a)

    sign_in_with_wallet(admin, admin_key)

    assert_difference "WalletInvitation.count", 1 do
      post community_members_path(community_b), params: { wallet_address: wallet }
    end

    assert_redirected_to community_members_path(community_b)
  end

  test "invites a non-existent wallet via JSON" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    community.community_members.create!(member: admin, role: "admin")

    new_address = "0x1111111111111111111111111111111111111111"

    sign_in_with_wallet(admin, admin_key)

    assert_difference "WalletInvitation.count", 1 do
      post community_members_path(community), params: { wallet_address: new_address }, as: :json
    end

    assert_response :created
    assert_equal new_address.downcase, response.parsed_body.fetch("wallet_address")
    assert_equal admin.id, response.parsed_body.fetch("invited_by_member_id")
    assert_equal community.id, response.parsed_body.fetch("community_id")
    assert_equal "member", response.parsed_body.fetch("community_role")
  end

  private

  def sign_in_with_wallet(member, private_key)
    post nonce_session_path, params: { wallet_address: member.wallet_address }, as: :json
    challenge = response.parsed_body
    post session_path, params: {
      wallet_address: member.wallet_address,
      nonce: challenge.fetch("nonce"),
      signature: personal_sign(private_key, challenge.fetch("message"))
    }, as: :json
    assert_response :created
  end
end
