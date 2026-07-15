class CommunityMember < ApplicationRecord
  belongs_to :community
  belongs_to :member

  validates :role, inclusion: { in: %w[admin member] }
  validates :member_id, uniqueness: { scope: :community_id, message: "is already a member of this community" }
end
