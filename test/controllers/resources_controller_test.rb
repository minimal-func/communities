require "test_helper"

class ResourcesControllerTest < ActionDispatch::IntegrationTest
  test "resources require authentication" do
    get communities_path
    assert_response :unauthorized

    get threads_path
    assert_response :unauthorized

    get posts_path
    assert_response :unauthorized

    get comments_path
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
    }

    assert_response :created
    community = Community.find(response.parsed_body.fetch("id"))
    assert_equal member, community.created_by_member

    post threads_path, params: {
      community_id: community.id,
      title: "Introductions",
      body: "Say hello here."
    }

    assert_response :created
    thread = CommunityThread.find(response.parsed_body.fetch("id"))
    assert_equal community, thread.community
    assert_equal member, thread.author_member

    post posts_path, params: {
      community_thread_id: thread.id,
      body: "Hello from the first post."
    }

    assert_response :created
    post = Post.find(response.parsed_body.fetch("id"))
    assert_equal thread, post.community_thread
    assert_equal member, post.author_member

    post comments_path, params: {
      post_id: post.id,
      body: "Welcome."
    }

    assert_response :created
    comment = Comment.find(response.parsed_body.fetch("id"))
    assert_equal post, comment.post
    assert_equal member, comment.author_member
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
