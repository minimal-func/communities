class CommunitiesController < ApplicationController
  before_action :require_member
  before_action :set_community, only: %i[show edit update destroy]

  def index
    @communities = Community.order(created_at: :desc)

    respond_to do |format|
      format.html
      format.json { render json: @communities.map { |community| community_json(community) } }
    end
  end

  def show
    @threads = @community.community_threads.order(created_at: :desc)

    respond_to do |format|
      format.html
      format.json { render json: community_json(@community) }
    end
  end

  def new
    @community = Community.new

    respond_to do |format|
      format.html
      format.json { render json: community_json(@community) }
    end
  end

  def create
    @community = current_member.communities.create!(community_params)

    respond_to do |format|
      format.html { redirect_to @community, notice: "Community created." }
      format.json { render json: community_json(@community), status: :created }
    end
  rescue ActiveRecord::RecordInvalid => error
    @community = error.record

    respond_to do |format|
      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity }
    end
  end

  def edit; end

  def update
    @community.update!(community_params)

    respond_to do |format|
      format.html { redirect_to @community, notice: "Community updated." }
      format.json { render json: community_json(@community) }
    end
  rescue ActiveRecord::RecordInvalid => error
    @community = error.record

    respond_to do |format|
      format.html { render :edit, status: :unprocessable_entity }
      format.json { render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity }
    end
  end

  def destroy
    @community.destroy!

    respond_to do |format|
      format.html { redirect_to communities_path, notice: "Community deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_community
    @community = Community.find(params[:id])
  end

  def community_params
    (params[:community] || params).permit(:name, :slug, :description)
  end

  def community_json(community)
    {
      id: community.id,
      created_by_member_id: community.created_by_member_id,
      name: community.name,
      slug: community.slug,
      description: community.description,
      created_at: community.created_at,
      updated_at: community.updated_at
    }
  end
end
