class Comment < ApplicationRecord
  belongs_to :post
  belongs_to :author_member, class_name: "Member"

  has_many :reports, as: :reportable, dependent: :destroy

  validates :body, presence: true

  default_scope -> { order(created_at: :asc) }
end
