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
