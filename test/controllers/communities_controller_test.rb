require "test_helper"

class CommunitiesControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication for create" do
    post communities_path, params: { name: "Builders", slug: "builders" }

    assert_redirected_to login_path
  end

  test "requires authentication for index via JSON" do
    get communities_path, headers: { "Accept" => "application/json" }

    assert_response :unauthorized
  end

  test "lists communities for authenticated member" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    sign_in_with_wallet(member, private_key)

    get communities_path

    assert_response :success
  end

  test "shows community to authenticated member" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    community.community_members.create!(member: member, role: "admin")
    sign_in_with_wallet(member, private_key)

    get community_path(community)

    assert_response :success
  end

  test "member can create a community" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    sign_in_with_wallet(member, private_key)

    assert_difference "Community.count", 1 do
      post communities_path, params: { name: "Builders", slug: "builders" }
    end

    community = Community.last
    assert_redirected_to community_path(community)
    assert community.community_members.exists?(member: member, role: "admin")
    assert_equal member, community.created_by_member
  end

  test "creates community via JSON" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    sign_in_with_wallet(member, private_key)

    post communities_path, params: { name: "Builders", slug: "builders" }, as: :json

    assert_response :created
    assert_equal "Builders", response.parsed_body.fetch("name")
    assert_equal member.id, response.parsed_body.fetch("created_by_member_id")
  end

  test "validates community name presence" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    sign_in_with_wallet(member, private_key)

    post communities_path, params: { name: "", slug: "builders" }

    assert_response :unprocessable_entity
  end

  test "community admin can update community" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Original", slug: "original", created_by_member: member)
    community.community_members.create!(member: member, role: "admin")
    sign_in_with_wallet(member, private_key)

    patch community_path(community), params: { name: "Updated" }

    assert_redirected_to community_path(community)
    assert_equal "Updated", community.reload.name
  end

  test "non-admin cannot update community" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key))
    community = Community.create!(name: "Original", slug: "original", created_by_member: admin)
    community.community_members.create!(member: admin, role: "admin")

    other_key = ethereum_private_key
    other = Member.create!(wallet_address: ethereum_address(other_key))
    sign_in_with_wallet(other, other_key)

    patch community_path(community), params: { name: "Hacked" }

    assert_redirected_to community_path(community)
    assert_equal "Original", community.reload.name
  end

  test "community admin can destroy community" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    community.community_members.create!(member: member, role: "admin")
    sign_in_with_wallet(member, private_key)

    assert_difference "Community.count", -1 do
      delete community_path(community)
    end

    assert_redirected_to communities_path
  end

  test "index excludes secret communities from non-members" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key))
    secret = Community.create!(name: "Secret", slug: "secret", created_by_member: admin, visibility: "secret")
    secret.community_members.create!(member: admin, role: "admin")

    member_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(member_key))
    sign_in_with_wallet(member, member_key)

    get communities_path, headers: { "Accept" => "application/json" }

    assert_response :success
    refute_includes response.parsed_body.map { |c| c.fetch("slug") }, "secret"
  end

  test "index includes secret communities for members" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key))
    secret = Community.create!(name: "Secret", slug: "secret", created_by_member: admin, visibility: "secret")
    secret.community_members.create!(member: admin, role: "admin")
    sign_in_with_wallet(admin, admin_key)

    get communities_path, headers: { "Accept" => "application/json" }

    assert_response :success
    assert_includes response.parsed_body.map { |c| c.fetch("slug") }, "secret"
  end

  test "member can join an open community" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key))
    community = Community.create!(name: "Open", slug: "open", created_by_member: admin, visibility: "open")
    community.community_members.create!(member: admin, role: "admin")

    member_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(member_key))
    sign_in_with_wallet(member, member_key)

    assert_difference "community.community_members.count", 1 do
      post join_community_path(community)
    end

    assert_redirected_to community_path(community)
    assert_equal "You joined Open.", flash[:notice]
    assert community.community_members.active.exists?(member: member, role: "member")
  end

  test "member can request to join a closed community" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key))
    community = Community.create!(name: "Closed", slug: "closed", created_by_member: admin, visibility: "closed")
    community.community_members.create!(member: admin, role: "admin")

    member_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(member_key))
    sign_in_with_wallet(member, member_key)

    assert_difference "community.community_members.count", 1 do
      post join_community_path(community)
    end

    assert_redirected_to community_path(community)
    assert_equal "Request to join sent. An admin will review it.", flash[:notice]
    assert community.community_members.pending.exists?(member: member)
  end

  test "cannot join a secret community" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key))
    community = Community.create!(name: "Secret", slug: "secret", created_by_member: admin, visibility: "secret")
    community.community_members.create!(member: admin, role: "admin")

    member_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(member_key))
    sign_in_with_wallet(member, member_key)

    assert_no_difference "community.community_members.count" do
      post join_community_path(community), headers: { "Accept" => "application/json" }
    end

    assert_response :not_found
  end

  test "already pending member is told request is pending" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key))
    community = Community.create!(name: "Closed", slug: "closed", created_by_member: admin, visibility: "closed")
    community.community_members.create!(member: admin, role: "admin")

    member_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(member_key))
    community.community_members.create!(member: member, role: "member", requested_at: Time.current)
    sign_in_with_wallet(member, member_key)

    assert_no_difference "community.community_members.count" do
      post join_community_path(community)
    end

    assert_redirected_to community_path(community)
    assert_equal "Your request to join is pending approval.", flash[:alert]
  end

  test "secret community shows not found to non-members" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key))
    community = Community.create!(name: "Secret", slug: "secret", created_by_member: admin, visibility: "secret")
    community.community_members.create!(member: admin, role: "admin")

    member_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(member_key))
    sign_in_with_wallet(member, member_key)

    get community_path(community), headers: { "Accept" => "application/json" }

    assert_response :not_found
  end

  test "closed community page is visible to non-members without threads" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key))
    community = Community.create!(name: "Closed", slug: "closed", created_by_member: admin, visibility: "closed")
    community.community_members.create!(member: admin, role: "admin")
    community.community_threads.create!(title: "Hidden thread", author_member: admin)

    member_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(member_key))
    sign_in_with_wallet(member, member_key)

    get community_path(community)

    assert_response :success
    assert_includes response.body, "Request to join"
    refute_includes response.body, "Hidden thread"
  end

  test "creates a community with a visibility" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    sign_in_with_wallet(member, private_key)

    post communities_path, params: { name: "Secret Builders", slug: "secret-builders", visibility: "secret" }

    assert_response :redirect
    assert_equal "secret", Community.last.visibility
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
