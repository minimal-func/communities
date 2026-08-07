class CommunityThread < ApplicationRecord
  include Sluggable

  belongs_to :community
  belongs_to :author_member, class_name: "Member"
  has_many :posts, dependent: :destroy

  slug_scope :community_id

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: { scope: :community_id }

  def self.ransackable_associations(auth_object = nil)
    ["author_member", "community", "posts"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["author_member_id", "body", "community_id", "created_at", "id", "slug", "title", "updated_at"]
  end

  private

  def base_slug
    title.to_s.parameterize.presence || SecureRandom.hex(6)
  end
end
