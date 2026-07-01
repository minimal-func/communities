class SessionsController < ApplicationController
  def new
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

  private

  def session_params
    params.permit(:wallet_address, :nonce, :signature)
  end

  def wallet_can_authenticate?(wallet_address)
    Member.exists?(wallet_address: wallet_address) ||
      WalletInvitation.pending.exists?(wallet_address: wallet_address)
  end

  def find_or_register_member(wallet_address)
    Member.find_by(wallet_address: wallet_address) || register_invited_member(wallet_address)
  end

  def register_invited_member(wallet_address)
    invitation = WalletInvitation.pending.find_by!(wallet_address: wallet_address)
    member = Member.create!(wallet_address: wallet_address, invited_by_member: invitation.invited_by_member)
    invitation.accept!(member)
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
