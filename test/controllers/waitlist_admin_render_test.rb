require "test_helper"

class WaitlistAdminRenderTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "admin waitlist index renders community name and description" do
    sign_in admin_users(:one)
    entry = WaitlistEntry.create!(
      wallet_address: "0x1111111111111111111111111111111111111111",
      community_name: "Greenhaven Commons",
      community_description: "A solarpunk neighborhood."
    )

    get admin_waitlist_entries_path
    assert_response :success
    assert_match "Greenhaven Commons", response.body
    assert_match "A solarpunk neighborhood", response.body

    get admin_waitlist_entry_path(entry)
    assert_response :success
    assert_match "Greenhaven Commons", response.body
  end
end
