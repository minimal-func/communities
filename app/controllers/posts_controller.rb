class PostsController < ApplicationController
  before_action :require_member
  before_action :set_post, only: %i[show update destroy]

  def index
    render json: Post.order(created_at: :desc).map { |post| post_json(post) }
  end

  def show
    render json: post_json(@post)
  end

  def create
    post = current_member.posts.create!(post_params)

    render json: post_json(post), status: :created
  rescue ActiveRecord::RecordInvalid => error
    render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
  end

  def update
    @post.update!(post_params)

    render json: post_json(@post)
  rescue ActiveRecord::RecordInvalid => error
    render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
  end

  def destroy
    @post.destroy!

    head :no_content
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.permit(:community_thread_id, :body)
  end

  def post_json(post)
    {
      id: post.id,
      community_thread_id: post.community_thread_id,
      author_member_id: post.author_member_id,
      body: post.body,
      created_at: post.created_at,
      updated_at: post.updated_at
    }
  end
end
