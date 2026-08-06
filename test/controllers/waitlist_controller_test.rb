require "test_helper"

class WaitlistControllerTest < ActionDispatch::IntegrationTest
  test "waitlist page renders" do
    get waitlist_path

    assert_response :success
    assert_select "h1", "Join the waitlist"
  end

  test "joins the waitlist and redirects to status page" do
    wallet_address = "0x1111111111111111111111111111111111111111"

    assert_difference "WaitlistEntry.count", 1 do
      post waitlist_path, params: { waitlist_entry: { wallet_address: wallet_address } }
    end

    assert_redirected_to waitlist_status_path(wallet: wallet_address)
    assert_predicate WaitlistEntry.find_by!(wallet_address: wallet_address), :pending?
  end

  test "rejects joining with an invalid wallet address" do
    assert_no_difference "WaitlistEntry.count" do
      post waitlist_path, params: { waitlist_entry: { wallet_address: "not-a-wallet" } }
    end

    assert_response :unprocessable_entity
  end

  test "rejects joining when wallet is already a member" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")

    assert_no_difference "WaitlistEntry.count" do
      post waitlist_path, params: { waitlist_entry: { wallet_address: member.wallet_address } }
    end

    assert_response :unprocessable_entity
  end

  test "status page shows pending status for a waitlisted wallet" do
    entry = WaitlistEntry.create!(wallet_address: "0x1111111111111111111111111111111111111111")

    get waitlist_status_path(wallet: entry.wallet_address)

    assert_response :success
    assert_match "Waiting for review", response.body
  end

  test "status page shows accepted for a member wallet" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")

    get waitlist_status_path(wallet: member.wallet_address)

    assert_response :success
    assert_match "Invitation accepted", response.body
  end

  test "status page shows not on the waitlist for an unknown wallet" do
    get waitlist_status_path(wallet: "0x2222222222222222222222222222222222222222")

    assert_response :success
    assert_match "Not on the waitlist", response.body
  end

  test "status page renders without a wallet param" do
    get waitlist_status_path

    assert_response :success
  end
end
