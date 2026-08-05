class Community < ApplicationRecord
  belongs_to :created_by_member, class_name: "Member"
  has_many :community_threads, dependent: :destroy
  has_many :community_members, dependent: :destroy
  has_many :members, through: :community_members
  has_many :wallet_invitations, dependent: :nullify

  before_validation :normalize_slug

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  def admin?(member)
    community_members.active.exists?(member: member, role: "admin")
  end

  def to_param
    slug
  end

  def member?(member)
    community_members.active.exists?(member: member)
  end

  def banned_member?(member)
    community_members.banned.exists?(member: member)
  end

  private

  def normalize_slug
    self.slug = slug.to_s.parameterize if slug.present?
  end
end
