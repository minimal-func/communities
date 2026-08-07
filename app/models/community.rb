class Community < ApplicationRecord
  VISIBILITIES = %w[open closed secret].freeze

  belongs_to :created_by_member, class_name: "Member"
  has_many :community_threads, dependent: :destroy
  has_many :community_members, dependent: :destroy
  has_many :members, through: :community_members
  has_many :wallet_invitations, dependent: :nullify

  before_validation :normalize_slug

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :visibility, presence: true, inclusion: { in: VISIBILITIES }

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "created_by_member_id", "description", "id", "name", "slug", "updated_at", "visibility"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["community_members", "community_threads", "created_by_member", "members", "wallet_invitations"]
  end

  scope :visible_to_member, ->(member) do
    if member&.admin?
      all
    else
      where(
        "visibility <> 'secret' OR id IN (SELECT community_id FROM community_members WHERE member_id = :member_id AND banned_at IS NULL AND requested_at IS NULL)",
        member_id: member&.id
      )
    end
  end

  def self.visibility_options
    {
      "Open - anyone signed in can join" => "open",
      "Closed - members request to join, admins approve" => "closed",
      "Secret - only visible to members" => "secret"
    }
  end

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

  def pending_member?(member)
    community_members.pending.exists?(member: member)
  end

  def open?
    visibility == "open"
  end

  def closed?
    visibility == "closed"
  end

  def secret?
    visibility == "secret"
  end

  def visible_to?(member)
    return true if member&.admin?
    return true unless secret?
    member?(member)
  end

  def content_visible_to?(member)
    return true if member&.admin?
    return true if open?
    member?(member)
  end

  private

  def normalize_slug
    self.slug = slug.to_s.parameterize if slug.present?
  end
end
