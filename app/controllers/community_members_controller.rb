class CommunityMembersController < ApplicationController
  before_action :require_member
  before_action :set_community
  before_action :require_community_admin

  def index
    @members = @community.community_members.includes(:member).order(created_at: :desc)
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
      if @community.member?(member)
        flash.now[:alert] = "Member is already part of this community."
        @members = @community.community_members.includes(:member).order(created_at: :desc)
        @community_member = @community.community_members.build
        @pending_invitations = @community.wallet_invitations.pending.order(created_at: :desc)
        render :index, status: :unprocessable_entity
        return
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
    flash.now[:alert] = error.record.errors.full_messages.to_sentence
    @members = @community.community_members.includes(:member).order(created_at: :desc)
    @community_member = @community.community_members.build
    @pending_invitations = @community.wallet_invitations.pending.order(created_at: :desc)
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
      created_at: cm.created_at
    }
  end
end
