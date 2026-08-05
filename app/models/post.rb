class Post < ApplicationRecord
  include Sluggable

  belongs_to :community_thread
  belongs_to :author_member, class_name: "Member"
  has_many :comments, dependent: :destroy
  has_many :reports, as: :reportable, dependent: :destroy

  slug_scope :community_thread_id

  validates :body, presence: true, unless: -> { body_json.present? }
  validates :body_json, presence: true, unless: -> { body.present? }
  validates :visibility, presence: true, inclusion: { in: %w[community members public] }
  validates :slug, presence: true, uniqueness: { scope: :community_thread_id }

  scope :visible_to_member, ->(member, community = nil) do
    if member
      if community&.member?(member)
        all
      else
        where(visibility: %w[members public])
      end
    else
      where(visibility: "public")
    end
  end

  def self.visibility_options
    {
      "Community members" => "community",
      "All members" => "members",
      "Public" => "public"
    }
  end

  private

  def base_slug
    SecureRandom.hex(6)
  end
end
