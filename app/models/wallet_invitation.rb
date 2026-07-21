class WalletInvitation < ApplicationRecord
  belongs_to :invited_by_member, class_name: "Member"
  belongs_to :accepted_member, class_name: "Member", optional: true
  belongs_to :community, optional: true

  before_validation :normalize_wallet_address

  validates :wallet_address, presence: true, uniqueness: { scope: :community_id, message: "already invited to this community" }
  validate :wallet_address_must_be_ethereum_address
  validate :wallet_address_must_not_belong_to_existing_member, on: :create

  scope :pending, -> { where(accepted_at: nil) }

  def accept!(member)
    update!(accepted_member: member, accepted_at: Time.current)
    create_community_member!
  end

  private

  def create_community_member!
    return unless community

    accepted_member.community_members.create!(
      community: community,
      role: community_role.presence_in(%w[admin member]) || "member"
    )
  end

  def normalize_wallet_address
    self.wallet_address = EthereumWallet.normalize(wallet_address)
  end

  def wallet_address_must_be_ethereum_address
    return if wallet_address.blank? || EthereumWallet.valid_address?(wallet_address)

    errors.add(:wallet_address, "must be an Ethereum address")
  end

  def wallet_address_must_not_belong_to_existing_member
    return if wallet_address.blank? || !Member.exists?(wallet_address: wallet_address)

    errors.add(:wallet_address, "already belongs to a member")
  end
end
