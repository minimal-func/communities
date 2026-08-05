require "test_helper"

class LandingControllerTest < ActionDispatch::IntegrationTest
  test "signed-in members are redirected to their dashboard" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))

    post nonce_session_path, params: { wallet_address: member.wallet_address }, as: :json
    challenge = response.parsed_body
    post session_path, params: {
      wallet_address: member.wallet_address,
      nonce: challenge.fetch("nonce"),
      signature: personal_sign(private_key, challenge.fetch("message"))
    }, as: :json

    get root_path

    assert_redirected_to dashboard_path
  end
end
