require "test_helper"

class AdminUsersTest < ActionDispatch::IntegrationTest
  test "redirects guests to login" do
    get admin_users_path

    assert_redirected_to login_path
  end

  test "forbids non-admin members" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))

    sign_in_member(member, private_key)
    get admin_users_path

    assert_response :forbidden
  end

  test "admin can add users" do
    admin_private_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_private_key), admin: true)
    wallet_address = ethereum_address(ethereum_private_key)

    sign_in_member(admin, admin_private_key)

    assert_difference("Member.count", 1) do
      post admin_users_path, params: {
        member: {
          wallet_address: wallet_address,
          admin: "0"
        }
      }
    end

    assert_redirected_to admin_users_path
    member = Member.find_by!(wallet_address: wallet_address)
    assert_not member.admin?
  end

  private

  def sign_in_member(member, private_key)
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
