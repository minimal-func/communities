class ThreadsController < ApplicationController
  before_action :require_member
  before_action :set_thread, only: %i[show update destroy]

  def index
    render json: CommunityThread.order(created_at: :desc).map { |thread| thread_json(thread) }
  end

  def show
    render json: thread_json(@thread)
  end

  def create
    thread = current_member.community_threads.create!(thread_params)

    render json: thread_json(thread), status: :created
  rescue ActiveRecord::RecordInvalid => error
    render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
  end

  def update
    @thread.update!(thread_params)

    render json: thread_json(@thread)
  rescue ActiveRecord::RecordInvalid => error
    render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
  end

  def destroy
    @thread.destroy!

    head :no_content
  end

  private

  def set_thread
    @thread = CommunityThread.find(params[:id])
  end

  def thread_params
    params.permit(:community_id, :title, :body)
  end

  def thread_json(thread)
    {
      id: thread.id,
      community_id: thread.community_id,
      author_member_id: thread.author_member_id,
      title: thread.title,
      body: thread.body,
      created_at: thread.created_at,
      updated_at: thread.updated_at
    }
  end
end
