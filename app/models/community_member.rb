class CommunityMember < ApplicationRecord
  belongs_to :community
  belongs_to :member
  belongs_to :banned_by_member, class_name: "Member", optional: true

  validates :role, inclusion: { in: %w[admin member] }
  validates :member_id, uniqueness: { scope: :community_id, message: "is already a member of this community" }

  scope :active, -> { where(banned_at: nil, requested_at: nil) }
  scope :pending, -> { where(banned_at: nil).where.not(requested_at: nil) }
  scope :not_pending, -> { where(requested_at: nil) }
  scope :banned, -> { where.not(banned_at: nil) }

  def banned?
    banned_at.present?
  end

  def pending?
    banned_at.blank? && requested_at.present?
  end
end
