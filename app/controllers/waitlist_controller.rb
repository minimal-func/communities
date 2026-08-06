class WaitlistController < ApplicationController
  def index
    @entry = WaitlistEntry.new
  end

  def create
    @entry = WaitlistEntry.new(waitlist_entry_params)

    if @entry.save
      redirect_to waitlist_status_path(wallet: @entry.wallet_address), notice: "You’re on the waitlist. An admin will review your invitation."
    else
      render :index, status: :unprocessable_entity
    end
  end

  def status
    @wallet_address = EthereumWallet.normalize(params[:wallet]) if params[:wallet].present?

    if @wallet_address.present?
      @entry = WaitlistEntry.find_by(wallet_address: @wallet_address)
      @member = Member.find_by(wallet_address: @wallet_address)
    end
  end

  private

  def waitlist_entry_params
    params.require(:waitlist_entry).permit(:wallet_address, :community_name, :community_description)
  end
end
