class Comment < ApplicationRecord
  belongs_to :post
  belongs_to :author_member, class_name: "Member"

  validates :body, presence: true
end
