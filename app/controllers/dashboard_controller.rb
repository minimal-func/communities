class DashboardController < ApplicationController
  before_action :require_member

  def index
    @communities = current_member.member_communities.order(created_at: :desc)
    @threads = current_member.community_threads.order(created_at: :desc).limit(5)
    @posts = current_member.posts.order(created_at: :desc).limit(5)
    @comments = current_member.comments.order(created_at: :desc).limit(5)
  end
end
