require "test_helper"

class ReportTest < ActiveSupport::TestCase
  test "requires reason" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post = thread.posts.create!(body: "Post", author_member: member)
    report = post.reports.new(reporter_member: member)
    assert_not report.valid?
    assert_includes report.errors[:reason], "can't be blank"
  end

  test "defaults to pending status" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post = thread.posts.create!(body: "Post", author_member: member)
    report = post.reports.create!(reason: "Spam", reporter_member: member)
    assert report.pending?
    assert_equal "pending", report.status
  end

  test "belongs to reporter and reportable" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post = thread.posts.create!(body: "Post", author_member: member)
    report = post.reports.create!(reason: "Inappropriate", reporter_member: member)
    assert_equal member, report.reporter_member
    assert_equal post, report.reportable
  end

  test "can report a comment" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post = thread.posts.create!(body: "Post", author_member: member)
    comment = post.comments.create!(body: "Bad comment", author_member: member)
    report = comment.reports.create!(reason: "Harassment", reporter_member: member)
    assert_equal comment, report.reportable
    assert_equal "Comment", report.reportable_type
  end

  test "enforces valid status values" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post = thread.posts.create!(body: "Post", author_member: member)
    report = post.reports.new(reason: "Test", reporter_member: member, status: "invalid")
    assert_not report.valid?
    assert_includes report.errors[:status], "is not included in the list"
  end

  test "can transition through statuses" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post = thread.posts.create!(body: "Post", author_member: member)
    report = post.reports.create!(reason: "Test", reporter_member: member)

    assert report.pending?
    report.resolved!
    assert report.resolved?

    report.dismissed!
    assert report.dismissed?
  end

  test "destroys dependent reports when reportable is destroyed" do
    member = Member.create!(wallet_address: "0x1111111111111111111111111111111111111111")
    community = Community.create!(name: "Test", slug: "test", created_by_member: member)
    thread = community.community_threads.create!(title: "Hello", author_member: member)
    post = thread.posts.create!(body: "Post", author_member: member)
    post.reports.create!(reason: "Spam", reporter_member: member)

    assert_difference "Report.count", -1 do
      post.destroy
    end
  end
end
