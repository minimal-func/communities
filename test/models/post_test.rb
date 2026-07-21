require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "requires body" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.new(author_member: member)

    assert_not post_record.valid?
    assert_includes post_record.errors[:body], "can't be blank"
  end

  test "requires valid visibility" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.new(body: "Hello", author_member: member, visibility: "invalid")

    assert_not post_record.valid?
    assert_includes post_record.errors[:visibility], "is not included in the list"
  end

  test "defaults visibility" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "Hello", author_member: member)

    assert_equal "members", post_record.visibility
  end

  test "belongs to thread and author" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "Hello", author_member: member)

    assert_equal thread, post_record.community_thread
    assert_equal member, post_record.author_member
  end

  test "destroys dependent comments" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "Hello", author_member: member)
    post_record.comments.create!(body: "Nice!", author_member: member)

    assert_difference "Comment.count", -1 do
      post_record.destroy
    end
  end

  test "visible_to_member scope filters by visibility for guests" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    public_post = thread.posts.create!(body: "Public", author_member: member, visibility: "public")
    members_post = thread.posts.create!(body: "Members", author_member: member, visibility: "members")
    community_post = thread.posts.create!(body: "Community", author_member: member, visibility: "community")

    visible = thread.posts.visible_to_member(nil)

    assert_includes visible, public_post
    assert_not_includes visible, members_post
    assert_not_includes visible, community_post
  end

  test "visible_to_member scope for non-member sees public and members" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    other = Member.create!(wallet_address: "0x2222222222222222222222222222222222222222")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    public_post = thread.posts.create!(body: "Public", author_member: member, visibility: "public")
    members_post = thread.posts.create!(body: "Members", author_member: member, visibility: "members")
    community_post = thread.posts.create!(body: "Community", author_member: member, visibility: "community")

    visible = thread.posts.visible_to_member(other, community)

    assert_includes visible, public_post
    assert_includes visible, members_post
    assert_not_includes visible, community_post
  end

  test "visible_to_member scope for member sees all" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    community.community_members.create!(member: member, role: "admin")
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    public_post = thread.posts.create!(body: "Public", author_member: member, visibility: "public")
    members_post = thread.posts.create!(body: "Members", author_member: member, visibility: "members")
    community_post = thread.posts.create!(body: "Community", author_member: member, visibility: "community")

    visible = thread.posts.visible_to_member(member, community)

    assert_includes visible, public_post
    assert_includes visible, members_post
    assert_includes visible, community_post
  end
end
