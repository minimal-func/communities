class PostsController < ApplicationController
  before_action :require_member
  before_action :set_thread, only: %i[index new create]
  before_action :set_post, only: %i[show edit update destroy]
  before_action :require_post_author_or_admin, only: %i[edit update destroy]

  def index
    @posts = @thread.posts.order(created_at: :asc)

    respond_to do |format|
      format.html
      format.json { render json: @posts.map { |post| post_json(post) } }
    end
  end

  def show
    @comments = @post.comments.includes(:author_member)

    respond_to do |format|
      format.html
      format.json { render json: post_json(@post) }
    end
  end

  def new
    @post = @thread.posts.new

    respond_to do |format|
      format.html
      format.json { render json: post_json(@post) }
    end
  end

  def create
    @post = current_member.posts.create!(post_params.merge(community_thread_id: params[:thread_id]))

    respond_to do |format|
      format.html { redirect_to thread_path(@post.community_thread), notice: "Post created." }
      format.json { render json: post_json(@post), status: :created }
    end
  rescue ActiveRecord::RecordInvalid => error
    @post = error.record

    respond_to do |format|
      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity }
    end
  end

  def edit; end

  def update
    @post.update!(post_params)

    respond_to do |format|
      format.html { redirect_to thread_path(@post.community_thread), notice: "Post updated." }
      format.json { render json: post_json(@post) }
    end
  rescue ActiveRecord::RecordInvalid => error
    @post = error.record

    respond_to do |format|
      format.html { render :edit, status: :unprocessable_entity }
      format.json { render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity }
    end
  end

  def destroy
    thread = @post.community_thread
    @post.destroy!

    respond_to do |format|
      format.html { redirect_to thread_path(thread), notice: "Post deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_thread
    @thread = CommunityThread.find(params[:thread_id])
  end

  def set_post
    @post = Post.find(params[:id])
  end

  def require_post_author_or_admin
    return if @post.author_member == current_member || current_member.admin?

    respond_to do |format|
      format.html { redirect_to thread_path(@post.community_thread), alert: "You don't have permission to do that." }
      format.json { render json: { error: "Forbidden" }, status: :forbidden }
    end
  end

  def post_params
    (params[:post] || params).permit(:community_thread_id, :body, :visibility)
  end

  def post_json(post)
    {
      id: post.id,
      community_thread_id: post.community_thread_id,
      author_member_id: post.author_member_id,
      body: post.body,
      visibility: post.visibility,
      created_at: post.created_at,
      updated_at: post.updated_at
    }
  end
end
