class WalletInvitationsController < ApplicationController
  before_action :authenticate_admin_member!, only: %i[index new create]

  def index
    @wallet_invitations = current_member.sent_wallet_invitations.order(created_at: :desc)
  end

  def new
    @wallet_invitation = current_member.sent_wallet_invitations.build
    @wallet_invitations = current_member.sent_wallet_invitations.order(created_at: :desc)
  end

  def create
    invitation = current_member.sent_wallet_invitations.create!(invitation_params)

    respond_to do |format|
      format.html { redirect_to new_wallet_invitation_path, notice: "Invitation created." }
      format.json { render json: invitation_json(invitation), status: :created }
    end
  rescue ActiveRecord::RecordInvalid => error
    respond_to do |format|
      format.html do
        @wallet_invitation = error.record
        @wallet_invitations = current_member.sent_wallet_invitations.order(created_at: :desc)
        flash.now[:alert] = @wallet_invitation.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
      format.json { render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity }
    end
  end

  private

  def invitation_params
    params.permit(:wallet_address)
  end

  def invitation_json(invitation)
    {
      id: invitation.id,
      wallet_address: invitation.wallet_address,
      invited_by_member_id: invitation.invited_by_member_id,
      accepted_at: invitation.accepted_at
    }
  end

  def require_member_for_wallet_invitations
    return if current_member

    if request.get?
      redirect_to login_path, alert: "Sign in to invite wallets."
    else
      render json: { error: "Authentication required" }, status: :unauthorized
    end
  end
end
