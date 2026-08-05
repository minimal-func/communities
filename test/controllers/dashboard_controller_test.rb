require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get dashboard_path

    assert_redirected_to login_path
  end

  test "renders dashboard for authenticated member" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    sign_in_with_wallet(member, private_key)

    get dashboard_path

    assert_response :success
    assert_select "h1", "Your Dashboard"
  end

  test "shows the member's communities" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Builders", slug: "builders", created_by_member: member)
    community.community_members.create!(member: member, role: "admin")
    sign_in_with_wallet(member, private_key)

    get dashboard_path

    assert_response :success
    assert_select "td", text: "Builders"
    assert_select "td", text: "admin"
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
