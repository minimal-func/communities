class Report < ApplicationRecord
  belongs_to :reporter_member, class_name: "Member"
  belongs_to :reportable, polymorphic: true
  belongs_to :resolved_by_member, class_name: "Member", optional: true

  validates :reason, presence: true

  enum :status, { pending: "pending", resolved: "resolved", dismissed: "dismissed" }, validate: true
end
