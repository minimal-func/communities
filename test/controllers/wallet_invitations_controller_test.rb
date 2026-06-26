require "test_helper"

class WalletInvitationsControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    post wallet_invitations_path, params: { wallet_address: "0x1111111111111111111111111111111111111111" }

    assert_response :unauthorized
  end
end
