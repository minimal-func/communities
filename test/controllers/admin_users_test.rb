require "test_helper"

class AdminUsersTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "redirects guests to admin login" do
    get admin_users_path

    assert_redirected_to new_admin_user_session_path
  end

  test "admin can view users list" do
    sign_in admin_users(:one)

    get admin_users_path

    assert_response :success
  end

  test "admin can add users" do
    sign_in admin_users(:one)

    wallet_address = ethereum_address(ethereum_private_key)

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
end
