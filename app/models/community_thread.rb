class CommunityThread < ApplicationRecord
  include Sluggable

  belongs_to :community
  belongs_to :author_member, class_name: "Member"
  has_many :posts, dependent: :destroy

  slug_scope :community_id

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: { scope: :community_id }

  private

  def base_slug
    title.to_s.parameterize.presence || SecureRandom.hex(6)
  end
end
