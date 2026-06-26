class WalletInvitationsController < ApplicationController
  before_action :require_member

  def create
    invitation = current_member.sent_wallet_invitations.create!(invitation_params)

    render json: {
      id: invitation.id,
      wallet_address: invitation.wallet_address,
      invited_by_member_id: invitation.invited_by_member_id,
      accepted_at: invitation.accepted_at
    }, status: :created
  rescue ActiveRecord::RecordInvalid => error
    render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
  end

  private

  def invitation_params
    params.permit(:wallet_address)
  end
end
