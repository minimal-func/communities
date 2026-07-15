require "test_helper"

class ResourcesControllerTest < ActionDispatch::IntegrationTest
  test "resources require authentication" do
    get communities_path, headers: { "Accept" => "application/json" }
    assert_response :unauthorized

    get comments_path, headers: { "Accept" => "application/json" }
    assert_response :unauthorized
  end

  test "member can create community thread post and comment" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    sign_in_with_wallet(member, private_key)

    post communities_path, params: {
      name: "Builders",
      slug: "builders",
      description: "People building in public."
    }, as: :json

    assert_response :created
    community = Community.find(response.parsed_body.fetch("id"))
    assert_equal member, community.created_by_member

    post community_threads_path(community), params: {
      title: "Introductions",
      body: "Say hello here."
    }, as: :json

    assert_response :created
    thread = CommunityThread.find(response.parsed_body.fetch("id"))
    assert_equal community, thread.community
    assert_equal member, thread.author_member

    post thread_posts_path(thread), params: {
      body: "Hello from the first post."
    }, as: :json

    assert_response :created
    post_record = Post.find(response.parsed_body.fetch("id"))
    assert_equal thread, post_record.community_thread
    assert_equal member, post_record.author_member

    post comments_path, params: {
      post_id: post_record.id,
      body: "Welcome."
    }, as: :json

    assert_response :created
    comment = Comment.find(response.parsed_body.fetch("id"))
    assert_equal post_record, comment.post
    assert_equal member, comment.author_member
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
