require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication for create" do
    post comments_path, params: { post_id: 0, body: "Nice!" }

    assert_redirected_to login_path
  end

  test "requires authentication for index" do
    get comments_path, headers: { "Accept" => "application/json" }

    assert_response :unauthorized
  end

  test "member can create a comment on a post" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "First!", author_member: member)
    sign_in_with_wallet(member, private_key)

    assert_difference "post_record.comments.count", 1 do
      post comments_path, params: { post_id: post_record.id, body: "Great post!" }
    end

    assert_response :created
    comment = post_record.comments.last
    assert_equal member, comment.author_member
    assert_equal "Great post!", comment.body
  end

  test "member can list comments" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "First!", author_member: member)
    post_record.comments.create!(body: "Nice!", author_member: member)
    sign_in_with_wallet(member, private_key)

    get comments_path, headers: { "Accept" => "application/json" }

    assert_response :success
    assert_kind_of Array, response.parsed_body
  end

  test "validates comment body presence" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "First!", author_member: member)
    sign_in_with_wallet(member, private_key)

    post comments_path, params: { post_id: post_record.id, body: "" }

    assert_response :unprocessable_entity
  end

  test "shows a comment" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "First!", author_member: member)
    comment = post_record.comments.create!(body: "Nice!", author_member: member)
    sign_in_with_wallet(member, private_key)

    get comment_path(comment), headers: { "Accept" => "application/json" }

    assert_response :success
    assert_equal comment.id, response.parsed_body.fetch("id")
  end

  test "member can update own comment" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "First!", author_member: member)
    comment = post_record.comments.create!(body: "Nice!", author_member: member)
    sign_in_with_wallet(member, private_key)

    patch comment_path(comment), params: { body: "Updated!" }

    assert_response :success
    assert_equal "Updated!", comment.reload.body
  end

  test "member can destroy own comment" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "First!", author_member: member)
    comment = post_record.comments.create!(body: "Nice!", author_member: member)
    sign_in_with_wallet(member, private_key)

    assert_difference "Comment.count", -1 do
      delete comment_path(comment)
    end

    assert_response :no_content
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
