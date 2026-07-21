class Post < ApplicationRecord
  belongs_to :community_thread
  belongs_to :author_member, class_name: "Member"
  has_many :comments, dependent: :destroy

  validates :body, presence: true
  validates :visibility, presence: true, inclusion: { in: %w[community members public] }

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
end
