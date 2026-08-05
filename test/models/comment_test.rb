require "test_helper"

class CommentTest < ActiveSupport::TestCase
  test "requires body" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "Post", author_member: member)
    comment = post_record.comments.new(author_member: member)

    assert_not comment.valid?
    assert_includes comment.errors[:body], "can't be blank"
  end

  test "belongs to post and author" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "Post", author_member: member)
    comment = post_record.comments.create!(body: "Nice!", author_member: member)

    assert_equal post_record, comment.post
    assert_equal member, comment.author_member
  end

  test "can reply to a comment up to 5 levels deep" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "Post", author_member: member)

    comment = post_record.comments.create!(body: "Level 1", author_member: member)
    4.times do |i|
      comment = comment.replies.create!(body: "Level #{i + 2}", author_member: member)
    end

    assert_equal 5, comment.depth
    assert_not comment.can_have_replies?
    assert comment.parent_comment.can_have_replies?
  end

  test "rejects replies deeper than 5 levels" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "Post", author_member: member)

    comment = post_record.comments.create!(body: "Level 1", author_member: member)
    4.times { comment = comment.replies.create!(body: "Deeper", author_member: member) }

    reply = comment.replies.new(body: "Too deep", author_member: member)

    assert_not reply.valid?
    assert_includes reply.errors[:parent_comment], "can't be nested deeper than 5 levels"
  end

  test "rejects reply whose parent belongs to a different post" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    first_post = thread.posts.create!(body: "First", author_member: member)
    second_post = thread.posts.create!(body: "Second", author_member: member)
    comment = first_post.comments.create!(body: "Nice!", author_member: member)

    reply = second_post.comments.new(body: "Reply", author_member: member, parent_comment: comment)

    assert_not reply.valid?
    assert_includes reply.errors[:parent_comment], "must belong to the same post"
  end

  test "destroys nested replies when parent is destroyed" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post_record = thread.posts.create!(body: "Post", author_member: member)

    comment = post_record.comments.create!(body: "Level 1", author_member: member)
    reply = comment.replies.create!(body: "Level 2", author_member: member)

    assert_difference "Comment.count", -2 do
      comment.destroy!
    end
  end
end
