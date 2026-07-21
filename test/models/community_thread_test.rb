require "test_helper"

class CommunityThreadTest < ActiveSupport::TestCase
  test "requires title" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.new(author_member: member)

    assert_not thread.valid?
    assert_includes thread.errors[:title], "can't be blank"
  end

  test "belongs to community and author" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)

    assert_equal community, thread.community
    assert_equal member, thread.author_member
  end

  test "destroys dependent posts" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    thread.posts.create!(body: "Post", author_member: member)

    assert_difference "Post.count", -1 do
      thread.destroy
    end
  end
end
