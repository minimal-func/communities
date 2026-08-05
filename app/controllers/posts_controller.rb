class PostsController < ApplicationController
  before_action :require_member, except: %i[index show]
  before_action :set_thread, only: %i[index new create]
  before_action :set_post, only: %i[show edit update destroy]
  before_action :require_visible_post, only: %i[show]
  before_action :require_content_community, only: %i[index show]
  before_action :require_membership_community, only: %i[new create]
  before_action :require_post_author_or_admin, only: %i[edit update destroy]

  def index
    @posts = @thread.posts.visible_to_member(current_member, @thread.community).order(created_at: :asc)

    respond_to do |format|
      format.html
      format.json { render json: @posts.map { |post| post_json(post) } }
    end
  end

  def show
    @comments = Comment.build_tree_for(@post)

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
    @post = current_member.posts.create!(post_params.to_h.merge(community_thread_id: @thread.id))

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
    @thread = CommunityThread.find_by!(slug: params[:thread_id])
  end

  def set_post
    @post = Post.find_by!(slug: params[:id])
  end

  def require_content_community
    require_community_content!(@thread&.community || @post.community_thread.community)
  end

  def require_membership_community
    require_community_member!(@thread.community)
  end

  def require_visible_post
    return if Post.visible_to_member(current_member, @post.community_thread.community).exists?(id: @post.id)

    respond_to do |format|
      format.html { redirect_to thread_path(@post.community_thread), alert: "You don't have permission to view this post." }
      format.json { render json: { error: "Not Found" }, status: :not_found }
    end
  end

  def require_post_author_or_admin
    return if @post.author_member == current_member || current_member.admin?

    respond_to do |format|
      format.html { redirect_to thread_path(@post.community_thread), alert: "You don't have permission to do that." }
      format.json { render json: { error: "Forbidden" }, status: :forbidden }
    end
  end

  def post_params
    raw_params = (params[:post] || params)
    permitted_params = raw_params.except(:body_json).permit(:community_thread_id, :body, :visibility).to_h

    if raw_params.key?(:body_json)
      permitted_params[:body_json] = normalize_parameter_value(raw_params[:body_json])
    end

    permitted_params
  end

  def normalize_parameter_value(value)
    case value
    when ActionController::Parameters
      value.to_unsafe_h.transform_values { |nested| normalize_parameter_value(nested) }.deep_stringify_keys
    when Hash
      value.transform_values { |nested| normalize_parameter_value(nested) }.deep_stringify_keys
    else
      value
    end
  end

  def post_json(post)
    {
      id: post.id,
      slug: post.slug,
      community_thread_id: post.community_thread_id,
      author_member_id: post.author_member_id,
      body: post.body,
      body_json: post.body_json,
      visibility: post.visibility,
      created_at: post.created_at,
      updated_at: post.updated_at
    }
  end
end
