class CommentsController < ApplicationController
  before_action :require_member
  before_action :set_comment, only: %i[show update destroy]
  before_action :set_post, only: %i[create]
  before_action :require_content_community, only: %i[show]
  before_action :require_membership_community, only: %i[create]

  def index
    render json: Comment.where(parent_comment_id: nil).map { |comment| comment_json(comment) }
  end

  def show
    render json: comment_json(@comment)
  end

  def create
    comment = current_member.comments.new(comment_params.to_h.except(:post_id, "post_id").merge(post: @post))

    if comment.save
      respond_to do |format|
        format.html { redirect_to post_path(comment.post), notice: "Comment added." }
        format.json { render json: comment_json(comment), status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_to post_path(@post), alert: comment.errors.full_messages.to_sentence }
        format.json { render json: { errors: comment.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update
    @comment.update!(comment_params)

    render json: comment_json(@comment)
  rescue ActiveRecord::RecordInvalid => error
    render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
  end

  def destroy
    @comment.destroy!

    respond_to do |format|
      format.html { redirect_to post_path(@comment.post), notice: "Comment deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def set_post
    @post = Post.find_by!(slug: comment_params[:post_id])
  end

  def require_content_community
    require_community_content!(@comment.post.community_thread.community)
  end

  def require_membership_community
    require_community_member!(@post.community_thread.community)
  end

  def comment_params
    raw_params = (params[:comment] || params)
    permitted_params = raw_params.except(:body_json).permit(:post_id, :body, :parent_comment_id).to_h

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

  def comment_json(comment)
    {
      id: comment.id,
      post_id: comment.post_id,
      parent_comment_id: comment.parent_comment_id,
      depth: comment.depth,
      author_member_id: comment.author_member_id,
      body: comment.body,
      body_json: comment.body_json,
      created_at: comment.created_at,
      updated_at: comment.updated_at,
      replies: comment.replies.map { |reply| comment_json(reply) }
    }
  end
end
