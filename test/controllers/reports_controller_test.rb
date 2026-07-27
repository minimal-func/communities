require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication for new" do
    get new_post_report_path(post_id: 0)
    assert_redirected_to login_path
  end

  test "requires authentication for create" do
    post post_reports_path(post_id: 0), params: { report: { reason: "Spam" } }
    assert_redirected_to login_path
  end

  test "requires authentication for index" do
    get reports_path
    assert_redirected_to login_path
  end

  test "requires admin for index" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    sign_in_with_wallet(member, private_key)
    get reports_path
    assert_response :forbidden
  end

  test "renders new report form for a post" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "First!", author_member: member)
    sign_in_with_wallet(member, private_key)
    get new_post_report_path(post_record)
    assert_response :success
  end

  test "renders new report form for a comment" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "First!", author_member: member)
    comment = post_record.comments.create!(body: "Bad comment", author_member: member)
    sign_in_with_wallet(member, private_key)
    get new_comment_report_path(comment)
    assert_response :success
  end

  test "member can report a post" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "First!", author_member: member)
    sign_in_with_wallet(member, private_key)
    assert_difference "post_record.reports.count", 1 do
      post post_reports_path(post_record), params: { report: { reason: "This is spam." } }
    end
    assert_redirected_to post_path(post_record)
    report = post_record.reports.last
    assert_equal member, report.reporter_member
    assert_equal "This is spam.", report.reason
    assert report.pending?
  end

  test "member can report a comment" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "First!", author_member: member)
    comment = post_record.comments.create!(body: "Bad comment", author_member: member)
    sign_in_with_wallet(member, private_key)
    assert_difference "comment.reports.count", 1 do
      post comment_reports_path(comment), params: { report: { reason: "Harassment" } }
    end
    assert_redirected_to post_path(post_record)
    report = comment.reports.last
    assert_equal member, report.reporter_member
    assert_equal "Harassment", report.reason
  end

  test "validates report reason presence" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "First!", author_member: member)
    sign_in_with_wallet(member, private_key)
    post post_reports_path(post_record), params: { report: { reason: "" } }
    assert_response :unprocessable_entity
  end

  test "admin can list all reports" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key), admin: true)
    member_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(member_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "First!", author_member: member)
    post_record.reports.create!(reason: "Spam", reporter_member: member)
    sign_in_with_wallet(admin, admin_key)
    get reports_path
    assert_response :success
  end

  test "admin can resolve a report" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key), admin: true)
    member_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(member_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "First!", author_member: member)
    report = post_record.reports.create!(reason: "Spam", reporter_member: member)
    sign_in_with_wallet(admin, admin_key)
    patch report_path(report), params: { status: :resolved }
    assert_redirected_to reports_path
    assert report.reload.resolved?
    assert_equal admin, report.reload.resolved_by_member
    assert_not_nil report.reload.resolved_at
  end

  test "admin can dismiss a report" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key), admin: true)
    member_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(member_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "First!", author_member: member)
    report = post_record.reports.create!(reason: "Spam", reporter_member: member)
    sign_in_with_wallet(admin, admin_key)
    patch report_path(report), params: { status: :dismissed }
    assert_redirected_to reports_path
    assert report.reload.dismissed?
  end

  test "non-admin cannot resolve a report" do
    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key), admin: true)
    member_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(member_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: admin)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "First!", author_member: member)
    report = post_record.reports.create!(reason: "Spam", reporter_member: member)
    sign_in_with_wallet(member, member_key)
    patch report_path(report), params: { status: :resolved }
    assert_response :forbidden
    assert report.reload.pending?
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
