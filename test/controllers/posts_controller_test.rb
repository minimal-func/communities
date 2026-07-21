require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication for create" do
    post thread_posts_path(thread_id: 0), params: { body: "Hello" }

    assert_redirected_to login_path
  end

  test "member can create a post in a thread" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    sign_in_with_wallet(member, private_key)

    assert_difference "thread.posts.count", 1 do
      post thread_posts_path(thread), params: { body: "My first post." }
    end

    post_record = Post.last
    assert_redirected_to thread_path(thread)
    assert_equal member, post_record.author_member
  end

  test "creates post via JSON" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    sign_in_with_wallet(member, private_key)

    post thread_posts_path(thread), params: { body: "Hello" }, as: :json

    assert_response :created
    assert_equal "Hello", response.parsed_body.fetch("body")
    assert_equal member.id, response.parsed_body.fetch("author_member_id")
  end

  test "validates post body presence" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    sign_in_with_wallet(member, private_key)

    post thread_posts_path(thread), params: { body: "" }

    assert_response :unprocessable_entity
  end

  test "post author can update post" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "Original", author_member: member)
    sign_in_with_wallet(member, private_key)

    patch post_path(post_record), params: { body: "Updated" }

    assert_redirected_to thread_path(thread)
    assert_equal "Updated", post_record.reload.body
  end

  test "non-author cannot update post" do
    author_key = ethereum_private_key
    author = Member.create!(wallet_address: ethereum_address(author_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: author)
    thread = community.community_threads.create!(title: "Hello", author_member: author)
    post_record = thread.posts.create!(body: "Original", author_member: author)

    other_key = ethereum_private_key
    other = Member.create!(wallet_address: ethereum_address(other_key))
    sign_in_with_wallet(other, other_key)

    patch post_path(post_record), params: { body: "Hacked" }

    assert_redirected_to thread_path(thread)
    assert_equal "Original", post_record.reload.body
  end

  test "admin can update any post" do
    author_key = ethereum_private_key
    author = Member.create!(wallet_address: ethereum_address(author_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: author)
    thread = community.community_threads.create!(title: "Hello", author_member: author)
    post_record = thread.posts.create!(body: "Original", author_member: author)

    admin_key = ethereum_private_key
    admin = Member.create!(wallet_address: ethereum_address(admin_key), admin: true)
    sign_in_with_wallet(admin, admin_key)

    patch post_path(post_record), params: { body: "Admin edited" }

    assert_redirected_to thread_path(thread)
    assert_equal "Admin edited", post_record.reload.body
  end

  test "post author can destroy post" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "Hello", author_member: member)
    sign_in_with_wallet(member, private_key)

    assert_difference "Post.count", -1 do
      delete post_path(post_record)
    end

    assert_redirected_to thread_path(thread)
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
