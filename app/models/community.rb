class Community < ApplicationRecord
  belongs_to :created_by_member, class_name: "Member"
  has_many :community_threads, dependent: :destroy

  before_validation :normalize_slug

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  private

  def normalize_slug
    self.slug = slug.to_s.parameterize if slug.present?
  end
end
