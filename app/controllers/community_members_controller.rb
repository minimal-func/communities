class CommunityMembersController < ApplicationController
  before_action :require_member
  before_action :set_community
  before_action :require_community_admin

  def index
    @members = @community.community_members.not_pending.includes(:member).order(created_at: :desc)
    @pending_requests = @community.community_members.pending.includes(:member).order(created_at: :desc)
    @community_member = @community.community_members.build
    @pending_invitations = @community.wallet_invitations.pending.order(created_at: :desc)

    respond_to do |format|
      format.html
      format.json { render json: @members.map { |cm| community_member_json(cm) } }
    end
  end

  def create
    wallet_address = EthereumWallet.normalize(params[:wallet_address])
    role = params[:role].presence_in(%w[admin member]) || "member"
    member = Member.find_by(wallet_address: wallet_address)

    if member
      if @community.banned_member?(member)
        return render_index_with(alert: "Member is banned from this community.", status: :unprocessable_entity)
      end

      if @community.member?(member)
        return render_index_with(alert: "Member is already part of this community.", status: :unprocessable_entity)
      end

      @community.community_members.create!(member: member, role: role)

      respond_to do |format|
        format.html { redirect_to community_members_path(@community), notice: "Member added." }
        format.json { head :created }
      end
    else
      invitation = current_member.sent_wallet_invitations.create!(
        wallet_address: wallet_address,
        community: @community,
        community_role: role
      )

      respond_to do |format|
        format.html { redirect_to community_members_path(@community), notice: "Invitation sent to #{invitation.wallet_address}." }
        format.json { render json: invitation_json(invitation), status: :created }
      end
    end
  rescue ActiveRecord::RecordInvalid => error
    render_index_with(alert: error.record.errors.full_messages.to_sentence, status: :unprocessable_entity)
  end

  def approve
    @community_member = @community.community_members.pending.find(params[:id])
    @community_member.update!(requested_at: nil)

    respond_to do |format|
      format.html { redirect_to community_members_path(@community), notice: "Membership request approved." }
      format.json { render json: community_member_json(@community_member) }
    end
  end

  def destroy
    @community_member = @community.community_members.find(params[:id])

    if @community_member.role == "admin" && !current_member.admin?
      redirect_to community_members_path(@community), alert: "Cannot remove another admin."
      return
    end

    @community_member.destroy!

    respond_to do |format|
      format.html { redirect_to community_members_path(@community), notice: "Member removed." }
      format.json { head :no_content }
    end
  end

  def ban
    @community_member = @community.community_members.find(params[:id])

    if @community_member.role == "admin" && !current_member.admin?
      redirect_to community_members_path(@community), alert: "Cannot ban another admin."
      return
    end

    @community_member.update!(banned_at: Time.current, banned_by_member_id: current_member.id)

    respond_to do |format|
      format.html { redirect_to community_members_path(@community), notice: "Member banned." }
      format.json { render json: community_member_json(@community_member) }
    end
  end

  def unban
    @community_member = @community.community_members.find(params[:id])
    @community_member.update!(banned_at: nil, banned_by_member_id: nil)

    respond_to do |format|
      format.html { redirect_to community_members_path(@community), notice: "Member unbanned." }
      format.json { render json: community_member_json(@community_member) }
    end
  end

  private

  def set_community
    @community = Community.find_by!(slug: params[:community_id])
  end

  def require_community_admin
    require_community_admin!(@community)
  end

  def render_index_with(alert:, status:)
    flash.now[:alert] = alert
    @members = @community.community_members.not_pending.includes(:member).order(created_at: :desc)
    @pending_requests = @community.community_members.pending.includes(:member).order(created_at: :desc)
    @community_member = @community.community_members.build
    @pending_invitations = @community.wallet_invitations.pending.order(created_at: :desc)
    render :index, status: status
  end

  def invitation_json(invitation)
    {
      id: invitation.id,
      wallet_address: invitation.wallet_address,
      invited_by_member_id: invitation.invited_by_member_id,
      community_id: invitation.community_id,
      community_role: invitation.community_role,
      accepted_at: invitation.accepted_at
    }
  end

  def community_member_json(cm)
    {
      id: cm.id,
      community_id: cm.community_id,
      member_id: cm.member_id,
      wallet_address: cm.member.wallet_address,
      role: cm.role,
      banned_at: cm.banned_at,
      requested_at: cm.requested_at,
      created_at: cm.created_at
    }
  end
end
