require "test_helper"

class ThreadsControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication for create" do
    post community_threads_path(community_id: 0), params: { title: "Hello" }

    assert_redirected_to login_path
  end

  test "shows thread to any visitor" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)

    get thread_path(thread)

    assert_response :success
  end

  test "member can create a thread in a community" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    community.community_members.create!(member: member, role: "admin")
    sign_in_with_wallet(member, private_key)

    assert_difference "community.community_threads.count", 1 do
      post community_threads_path(community), params: { title: "Introductions", body: "Welcome!" }
    end

    thread = CommunityThread.last
    assert_redirected_to thread_path(thread)
    assert_equal member, thread.author_member
  end

  test "creates thread via JSON" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    community.community_members.create!(member: member, role: "admin")
    sign_in_with_wallet(member, private_key)

    post community_threads_path(community), params: { title: "Hello" }, as: :json

    assert_response :created
    assert_equal "Hello", response.parsed_body.fetch("title")
    assert_equal community.id, response.parsed_body.fetch("community_id")
  end

  test "validates thread title presence" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    community.community_members.create!(member: member, role: "admin")
    sign_in_with_wallet(member, private_key)

    post community_threads_path(community), params: { title: "" }

    assert_response :unprocessable_entity
  end

  test "member can update a thread" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    sign_in_with_wallet(member, private_key)

    patch thread_path(thread), params: { title: "Updated" }

    assert_redirected_to thread_path(thread)
    assert_equal "Updated", thread.reload.title
  end

  test "member can destroy a thread" do
    private_key = ethereum_private_key
    member = Member.create!(wallet_address: ethereum_address(private_key))
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    sign_in_with_wallet(member, private_key)

    assert_difference "CommunityThread.count", -1 do
      delete thread_path(thread)
    end

    assert_redirected_to community_path(community)
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
