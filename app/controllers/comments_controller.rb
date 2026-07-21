class CommentsController < ApplicationController
  before_action :require_member
  before_action :set_comment, only: %i[show update destroy]
  before_action :set_post, only: %i[create]

  def index
    render json: Comment.order(created_at: :desc).map { |comment| comment_json(comment) }
  end

  def show
    render json: comment_json(@comment)
  end

  def create
    comment = current_member.comments.new(comment_params)

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
    @post = Post.find(comment_params[:post_id])
  end

  def comment_params
    (params[:comment] || params).permit(:post_id, :body)
  end

  def comment_json(comment)
    {
      id: comment.id,
      post_id: comment.post_id,
      author_member_id: comment.author_member_id,
      body: comment.body,
      created_at: comment.created_at,
      updated_at: comment.updated_at
    }
  end
end
