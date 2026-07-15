class Member < ApplicationRecord
  belongs_to :invited_by_member, class_name: "Member", optional: true
  has_many :sent_wallet_invitations,
    class_name: "WalletInvitation",
    foreign_key: :invited_by_member_id,
    dependent: :restrict_with_exception
  has_many :communities,
    foreign_key: :created_by_member_id,
    dependent: :restrict_with_exception
  has_many :community_threads,
    foreign_key: :author_member_id,
    dependent: :restrict_with_exception
  has_many :posts,
    foreign_key: :author_member_id,
    dependent: :restrict_with_exception
  has_many :comments,
    foreign_key: :author_member_id,
    dependent: :restrict_with_exception
  has_many :images, foreign_key: :author_member_id, dependent: :destroy
  has_many :community_members, dependent: :destroy
  has_many :member_communities, through: :community_members, source: :community

  before_validation :normalize_wallet_address

  validates :wallet_address, presence: true, uniqueness: true
  validate :wallet_address_must_be_ethereum_address

  scope :admins, -> { where(admin: true) }

  def self.ransackable_attributes(auth_object = nil)
    ["admin", "created_at", "id", "invited_by_member_id", "last_signed_in_at", "updated_at", "wallet_address"]
  end

  private

  def normalize_wallet_address
    self.wallet_address = EthereumWallet.normalize(wallet_address)
  end

  def wallet_address_must_be_ethereum_address
    return if wallet_address.blank? || EthereumWallet.valid_address?(wallet_address)

    errors.add(:wallet_address, "must be an Ethereum address")
  end
end
