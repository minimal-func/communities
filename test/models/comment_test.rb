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
end
