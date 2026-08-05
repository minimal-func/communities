class CommunitiesController < ApplicationController
  before_action :require_member
  before_action :set_community, only: %i[show edit update destroy join]
  before_action :require_community_visibility, only: %i[show join]
  before_action :require_community_admin, only: %i[edit update destroy]

  def index
    @communities = Community.visible_to_member(current_member).order(created_at: :desc)

    respond_to do |format|
      format.html
      format.json { render json: @communities.map { |community| community_json(community) } }
    end
  end

  def show
    @is_admin = current_member&.admin? || @community.admin?(current_member)
    @is_member = @community.member?(current_member)
    @is_pending = @community.pending_member?(current_member)
    @threads = @community.community_threads.order(created_at: :desc) if @community.content_visible_to?(current_member)

    respond_to do |format|
      format.html
      format.json { render json: community_json(@community) }
    end
  end

  def join
    if @community.member?(current_member)
      redirect_to @community, alert: "You are already a member of this community."
      return
    end

    if @community.banned_member?(current_member)
      redirect_to @community, alert: "You are banned from this community."
      return
    end

    if @community.pending_member?(current_member)
      redirect_to @community, alert: "Your request to join is pending approval."
      return
    end

    if @community.open?
      @community.community_members.create!(member: current_member, role: "member")
      redirect_to @community, notice: "You joined #{@community.name}."
    elsif @community.closed?
      @community.community_members.create!(member: current_member, role: "member", requested_at: Time.current)
      redirect_to @community, notice: "Request to join sent. An admin will review it."
    else
      render_not_found
    end
  rescue ActiveRecord::RecordInvalid => error
    redirect_to @community, alert: error.record.errors.full_messages.to_sentence
  end

  def new
    @community = Community.new

    respond_to do |format|
      format.html
      format.json { render json: community_json(@community) }
    end
  end

  def create
    @community = Community.new(community_params.merge(created_by_member_id: current_member.id))

    CommunityMember.transaction do
      @community.save!
      @community.community_members.create!(member: current_member, role: "admin")
    end

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
    @community = Community.find_by!(slug: params[:id])
  end

  def require_community_admin
    require_community_admin!(@community)
  end

  def require_community_visibility
    require_community_visibility!(@community)
  end

  def community_params
    (params[:community] || params).permit(:name, :slug, :description, :description_json, :visibility)
  end

  def community_json(community)
    {
      id: community.id,
      created_by_member_id: community.created_by_member_id,
      name: community.name,
      slug: community.slug,
      description: community.description,
      description_json: community.description_json,
      visibility: community.visibility,
      created_at: community.created_at,
      updated_at: community.updated_at
    }
  end
end
