require "test_helper"

class WalletInvitationsControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    post wallet_invitations_path, params: { wallet_address: "0x1111111111111111111111111111111111111111" }

    assert_redirected_to login_path
  end

  test "requires admin role" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    sign_in_with_wallet(member, private_key)

    post wallet_invitations_path, params: { wallet_address: "0x1111111111111111111111111111111111111111" }

    assert_response :forbidden
  end

  test "admin can create invitation" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key), admin: true)
    sign_in_with_wallet(admin, admin_key)

    assert_difference "WalletInvitation.count", 1 do
      post wallet_invitations_path, params: { wallet_address: "0x2222222222222222222222222222222222222222" }
    end

    assert_redirected_to new_wallet_invitation_path
    invitation = WalletInvitation.last
    assert_equal "0x2222222222222222222222222222222222222222".downcase, invitation.wallet_address
    assert_equal admin, invitation.invited_by_member
  end

  test "admin can create invitation via JSON" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key), admin: true)
    sign_in_with_wallet(admin, admin_key)

    post wallet_invitations_path, params: { wallet_address: "0x3333333333333333333333333333333333333333" }, as: :json

    assert_response :created
    assert_equal "0x3333333333333333333333333333333333333333".downcase, response.parsed_body.fetch("wallet_address")
    assert_equal admin.id, response.parsed_body.fetch("invited_by_member_id")
  end

  test "cannot invite the same wallet twice" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key), admin: true)
    sign_in_with_wallet(admin, admin_key)

    WalletInvitation.create!(wallet_address: "0x4444444444444444444444444444444444444444", invited_by_member: admin)

    post wallet_invitations_path, params: { wallet_address: "0x4444444444444444444444444444444444444444" }

    assert_response :unprocessable_entity
  end

  test "cannot invite an existing member" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key), admin: true)
    sign_in_with_wallet(admin, admin_key)

    Member.create!(wallet_address: "0x5555555555555555555555555555555555555555")

    post wallet_invitations_path, params: { wallet_address: "0x5555555555555555555555555555555555555555" }

    assert_response :unprocessable_entity
  end

  test "admin can view invitations" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key), admin: true)
    admin.sent_wallet_invitations.create!(wallet_address: "0x6666666666666666666666666666666666666666")
    sign_in_with_wallet(admin, admin_key)

    get wallet_invitations_path

    assert_response :success
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
