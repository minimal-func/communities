class CommunityMembersController < ApplicationController
  before_action :require_member
  before_action :set_community
  before_action :require_community_admin

  def index
    @members = @community.community_members.includes(:member).order(created_at: :desc)
    @community_member = @community.community_members.build

    respond_to do |format|
      format.html
      format.json { render json: @members.map { |cm| community_member_json(cm) } }
    end
  end

  def create
    member = Member.find_by(wallet_address: params[:wallet_address])

    if member.nil?
      flash.now[:alert] = "No member found with that wallet address."
      @members = @community.community_members.includes(:member).order(created_at: :desc)
      @community_member = @community.community_members.build
      render :index, status: :unprocessable_entity
      return
    end

    if @community.member?(member)
      flash.now[:alert] = "Member is already part of this community."
      @members = @community.community_members.includes(:member).order(created_at: :desc)
      @community_member = @community.community_members.build
      render :index, status: :unprocessable_entity
      return
    end

    @community.community_members.create!(member: member, role: "member")

    respond_to do |format|
      format.html { redirect_to community_members_path(@community), notice: "Member added." }
      format.json { head :created }
    end
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = "Could not add member."
    @members = @community.community_members.includes(:member).order(created_at: :desc)
    @community_member = @community.community_members.build
    render :index, status: :unprocessable_entity
  end

  def destroy
    @community_member = @community.community_members.find(params[:id])
    @community_member.destroy!

    respond_to do |format|
      format.html { redirect_to community_members_path(@community), notice: "Member removed." }
      format.json { head :no_content }
    end
  end

  private

  def set_community
    @community = Community.find(params[:community_id])
  end

  def require_community_admin
    require_community_admin!(@community)
  end

  def community_member_json(cm)
    {
      id: cm.id,
      community_id: cm.community_id,
      member_id: cm.member_id,
      wallet_address: cm.member.wallet_address,
      role: cm.role,
      created_at: cm.created_at
    }
  end
end
