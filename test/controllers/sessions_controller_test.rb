require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "does not issue a challenge for an uninvited wallet" do
    post nonce_session_path, params: { wallet_address: "0x1111111111111111111111111111111111111111" }

    assert_response :forbidden
  end

  test "existing member can sign in with wallet signature" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))

    post nonce_session_path, params: { wallet_address: member.wallet_address }
    assert_response :success

    challenge = response.parsed_body
    post session_path, params: {
      wallet_address: member.wallet_address,
      nonce: challenge.fetch("nonce"),
      signature: personal_sign(private_key, challenge.fetch("message"))
    }

    assert_response :created
    assert_equal member.wallet_address, response.parsed_body.fetch("wallet_address")
  end

  test "invited wallet signs in and becomes a member" do
    inviter_key = ethereum_private_key
    invitee_key = ethereum_private_key
    inviter = Member.create!(wallet_address: ethereum_address(inviter_key))
    invitee_address = ethereum_address(invitee_key)

    sign_in_with_wallet(inviter, inviter_key)

    post wallet_invitations_path, params: { wallet_address: invitee_address }, as: :json
    assert_response :created

    post nonce_session_path, params: { wallet_address: invitee_address }
    assert_response :success

    challenge = response.parsed_body
    post session_path, params: {
      wallet_address: invitee_address,
      nonce: challenge.fetch("nonce"),
      signature: personal_sign(invitee_key, challenge.fetch("message"))
    }

    assert_response :created

    member = Member.find_by!(wallet_address: invitee_address)
    invitation = WalletInvitation.find_by!(wallet_address: invitee_address)
    assert_equal inviter, member.invited_by_member
    assert_equal member, invitation.accepted_member
    assert_not_nil invitation.accepted_at
  end

  test "rejects invalid signatures" do
    private_key = ethereum_private_key
    other_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))

    post nonce_session_path, params: { wallet_address: member.wallet_address }
    challenge = response.parsed_body

    post session_path, params: {
      wallet_address: member.wallet_address,
      nonce: challenge.fetch("nonce"),
      signature: personal_sign(other_key, challenge.fetch("message"))
    }

    assert_response :unauthorized
  end

  private

  def sign_in_with_wallet(member, private_key)
    post nonce_session_path, params: { wallet_address: member.wallet_address }
    challenge = response.parsed_body
    post session_path, params: {
      wallet_address: member.wallet_address,
      nonce: challenge.fetch("nonce"),
      signature: personal_sign(private_key, challenge.fetch("message"))
    }
    assert_response :created
  end
end
