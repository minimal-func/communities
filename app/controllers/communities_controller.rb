class CommunitiesController < ApplicationController
  before_action :require_member
  before_action :set_community, only: %i[show update destroy]

  def index
    render json: Community.order(created_at: :desc).map { |community| community_json(community) }
  end

  def show
    render json: community_json(@community)
  end

  def create
    community = current_member.communities.create!(community_params)

    render json: community_json(community), status: :created
  rescue ActiveRecord::RecordInvalid => error
    render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
  end

  def update
    @community.update!(community_params)

    render json: community_json(@community)
  rescue ActiveRecord::RecordInvalid => error
    render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
  end

  def destroy
    @community.destroy!

    head :no_content
  end

  private

  def set_community
    @community = Community.find(params[:id])
  end

  def community_params
    params.permit(:name, :slug, :description)
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
