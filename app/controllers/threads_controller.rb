class ThreadsController < ApplicationController
  before_action :require_member
  before_action :set_community, only: %i[index new create]
  before_action :set_thread, only: %i[show edit update destroy]

  def index
    @threads = @community.community_threads.order(created_at: :desc)

    respond_to do |format|
      format.html
      format.json { render json: @threads.map { |thread| thread_json(thread) } }
    end
  end

  def show
    @posts = @thread.posts.order(created_at: :asc)

    respond_to do |format|
      format.html
      format.json { render json: thread_json(@thread) }
    end
  end

  def new
    @thread = @community.community_threads.new

    respond_to do |format|
      format.html
      format.json { render json: thread_json(@thread) }
    end
  end

  def create
    @thread = current_member.community_threads.create!(thread_params.merge(community_id: params[:community_id]))

    respond_to do |format|
      format.html { redirect_to thread_path(@thread), notice: "Thread created." }
      format.json { render json: thread_json(@thread), status: :created }
    end
  rescue ActiveRecord::RecordInvalid => error
    @thread = error.record

    respond_to do |format|
      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity }
    end
  end

  def edit; end

  def update
    @thread.update!(thread_params)

    respond_to do |format|
      format.html { redirect_to thread_path(@thread), notice: "Thread updated." }
      format.json { render json: thread_json(@thread) }
    end
  rescue ActiveRecord::RecordInvalid => error
    @thread = error.record

    respond_to do |format|
      format.html { render :edit, status: :unprocessable_entity }
      format.json { render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity }
    end
  end

  def destroy
    community = @thread.community
    @thread.destroy!

    respond_to do |format|
      format.html { redirect_to community, notice: "Thread deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_community
    @community = Community.find(params[:community_id])
  end

  def set_thread
    @thread = CommunityThread.find(params[:id])
  end

  def thread_params
    (params[:community_thread] || params).permit(:community_id, :title, :body)
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
