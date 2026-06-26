class WalletLoginChallenge < ApplicationRecord
  EXPIRATION = 10.minutes

  before_validation :normalize_wallet_address
  before_validation :set_defaults, on: :create

  validates :wallet_address, presence: true
  validates :nonce, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validate :wallet_address_must_be_ethereum_address

  scope :usable, -> { where(used_at: nil).where("expires_at > ?", Time.current) }

  def message
    <<~MESSAGE.strip
      Sign in to #{Rails.application.class.module_parent_name}

      Wallet: #{wallet_address}
      Nonce: #{nonce}
      Issued At: #{created_at.utc.iso8601}
    MESSAGE
  end

  def use!
    update!(used_at: Time.current)
  end

  private

  def normalize_wallet_address
    self.wallet_address = EthereumWallet.normalize(wallet_address)
  end

  def set_defaults
    self.nonce ||= SecureRandom.hex(32)
    self.expires_at ||= EXPIRATION.from_now
  end

  def wallet_address_must_be_ethereum_address
    return if wallet_address.blank? || EthereumWallet.valid_address?(wallet_address)

    errors.add(:wallet_address, "must be an Ethereum address")
  end
end
