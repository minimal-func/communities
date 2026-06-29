class CommunityThread < ApplicationRecord
  belongs_to :community
  belongs_to :author_member, class_name: "Member"
  has_many :posts, dependent: :destroy

  validates :title, presence: true
end
