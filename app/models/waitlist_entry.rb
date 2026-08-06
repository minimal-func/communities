class WaitlistEntry < ApplicationRecord
  STATUSES = %w[pending approved rejected accepted].freeze

  belongs_to :approved_by_admin_user, class_name: "AdminUser", optional: true
  belongs_to :accepted_member, class_name: "Member", optional: true
  belongs_to :community, optional: true

  before_validation :normalize_wallet_address

  validates :wallet_address, presence: true, uniqueness: true
  validates :community_name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :wallet_address_must_be_ethereum_address
  validate :wallet_address_must_not_belong_to_existing_member, on: :create

  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :rejected, -> { where(status: "rejected") }
  scope :accepted, -> { where(status: "accepted") }

  def self.ransackable_attributes(auth_object = nil)
    %w[
      id wallet_address status community_name community_description
      approved_at rejected_at accepted_at approved_by_admin_user_id
      accepted_member_id community_id created_at updated_at
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[approved_by_admin_user accepted_member community]
  end

  def pending?
    status == "pending"
  end

  def approved?
    status == "approved"
  end

  def accepted?
    status == "accepted"
  end

  def rejected?
    status == "rejected"
  end

  def approve!(admin_user)
    update!(
      status: "approved",
      approved_by_admin_user: admin_user,
      approved_at: Time.current,
      rejected_at: nil
    )
  end

  def reject!(admin_user)
    update!(
      status: "rejected",
      approved_by_admin_user: admin_user,
      rejected_at: Time.current,
      approved_at: nil
    )
  end

  def accept!(member)
    ApplicationRecord.transaction do
      update!(status: "accepted", accepted_member: member, accepted_at: Time.current)
      provision_community!(member)
    end
  end

  private

  # Founds the proposed community and makes the accepting member its first admin.
  def provision_community!(member)
    return unless community_name.present?
    return if community.present?

    community = Community.create!(
      name: community_name,
      slug: build_unique_slug(community_name),
      description: community_description,
      created_by_member: member
    )
    member.community_members.create!(community: community, role: "admin")
    update!(community_id: community.id)
  end

  def build_unique_slug(name)
    base = name.to_s.parameterize.presence || "community"
    slug = base
    suffix = 2
    while Community.exists?(slug: slug)
      slug = "#{base}-#{suffix}"
      suffix += 1
    end
    slug
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
