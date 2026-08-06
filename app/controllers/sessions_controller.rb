class SessionsController < ApplicationController
  def new
    redirect_to dashboard_path if current_member
  end

  def nonce
    wallet_address = EthereumWallet.normalize(session_params[:wallet_address])

    unless wallet_can_authenticate?(wallet_address)
      return render json: { error: "Wallet is not invited" }, status: :forbidden
    end

    challenge = WalletLoginChallenge.create!(wallet_address: wallet_address)
    render json: {
      wallet_address: challenge.wallet_address,
      nonce: challenge.nonce,
      message: challenge.message,
      expires_at: challenge.expires_at
    }
  end

  def create
    wallet_address = EthereumWallet.normalize(session_params[:wallet_address])
    challenge = WalletLoginChallenge.usable.find_by(nonce: session_params[:nonce], wallet_address: wallet_address)

    return render json: { error: "Challenge is invalid or expired" }, status: :unprocessable_entity unless challenge

    unless EthereumSignatureVerifier.valid_personal_signature?(
      wallet_address: wallet_address,
      message: challenge.message,
      signature: session_params[:signature]
    )
      return render json: { error: "Signature is invalid" }, status: :unauthorized
    end

    member = find_or_register_member(wallet_address)
    challenge.use!
    member.update!(last_signed_in_at: Time.current)
    session[:member_id] = member.id

    render json: member_json(member), status: :created
  end

  def destroy
    reset_session
    head :no_content
  end

  # Development-only shortcut to sign in without a wallet, for previews and
  # screenshots. Never reachable outside of the development environment.
  def demo
    return head(:forbidden) unless Rails.env.development?

    member = Member.find_by(wallet_address: demo_params[:wallet]) || Member.first
    session[:member_id] = member&.id
    redirect_to dashboard_path
  end

  private

  def demo_params
    params.permit(:wallet)
  end

  def session_params
    params.permit(:wallet_address, :nonce, :signature)
  end

  def wallet_can_authenticate?(wallet_address)
    Member.exists?(wallet_address: wallet_address) ||
      WalletInvitation.pending.exists?(wallet_address: wallet_address) ||
      WaitlistEntry.approved.exists?(wallet_address: wallet_address)
  end

  def find_or_register_member(wallet_address)
    Member.find_by(wallet_address: wallet_address) || register_invited_member(wallet_address)
  end

  def register_invited_member(wallet_address)
    if invitation = WalletInvitation.pending.find_by(wallet_address: wallet_address)
      member = Member.create!(wallet_address: wallet_address, invited_by_member: invitation.invited_by_member)
      invitation.accept!(member)
      return member
    end

    entry = WaitlistEntry.approved.find_by(wallet_address: wallet_address)
    raise ActiveRecord::RecordNotFound unless entry

    member = Member.create!(wallet_address: wallet_address)
    entry.accept!(member)
    member
  end

  def member_json(member)
    {
      id: member.id,
      wallet_address: member.wallet_address,
      invited_by_member_id: member.invited_by_member_id
    }
  end
end
