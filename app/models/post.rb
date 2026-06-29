class Post < ApplicationRecord
  belongs_to :community_thread
  belongs_to :author_member, class_name: "Member"
  has_many :comments, dependent: :destroy

  validates :body, presence: true
end
