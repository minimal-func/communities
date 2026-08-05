require "test_helper"

class HelpControllerTest < ActionDispatch::IntegrationTest
  test "renders the help page for guests" do
    get help_path

    assert_response :success
    assert_select "h1", "Help & getting started"
  end

  test "renders the help page for signed-in members" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))

    post nonce_session_path, params: { wallet_address: member.wallet_address }, as: :json
    challenge = response.parsed_body
    post session_path, params: {
      wallet_address: member.wallet_address,
      nonce: challenge.fetch("nonce"),
      signature: personal_sign(private_key, challenge.fetch("message"))
    }, as: :json

    get help_path

    assert_response :success
    assert_select "h1", "Help & getting started"
  end

  test "describes the current features" do
    get help_path

    assert_select "h2", text: /Sign in with your wallet/
    assert_select "h2", text: /Your dashboard/
    assert_select "h2", text: /Communities/
    assert_select "h2", text: /Threads/
    assert_select "h2", text: /Posts/
    assert_select "h2", text: /Comments/
    assert_select "h2", text: /The rich text editor/
    assert_select "h2", text: /Visibility & access/
    assert_select "h2", text: /Membership & roles/
    assert_select "h2", text: /Reports & moderation/
  end
end
