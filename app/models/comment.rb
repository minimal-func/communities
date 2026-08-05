class Comment < ApplicationRecord
  MAX_DEPTH = 5

  belongs_to :post
  belongs_to :author_member, class_name: "Member"
  belongs_to :parent_comment, class_name: "Comment", optional: true

  has_many :replies, class_name: "Comment", foreign_key: :parent_comment_id, dependent: :destroy
  has_many :reports, as: :reportable, dependent: :destroy

  validates :body, presence: true, unless: -> { body_json.present? }
  validates :body_json, presence: true, unless: -> { body.present? }
  before_validation :inherit_post_from_parent
  validate :parent_comment_belongs_to_same_post
  validate :parent_comment_within_max_depth

  default_scope -> { order(created_at: :asc) }

  def self.build_tree_for(post)
    comments = post.comments.includes(:author_member).to_a
    by_parent = comments.group_by(&:parent_comment_id)
    by_parent.fetch(nil, []).map { |comment| hydrate_replies(comment, by_parent) }
  end

  def self.hydrate_replies(comment, by_parent)
    replies = by_parent.fetch(comment.id, [])
    comment.association(:replies).loaded!
    comment.association(:replies).target = replies.map { |reply| hydrate_replies(reply, by_parent) }
    comment
  end

  def depth
    depth = 1
    current = self
    while (current = current.parent_comment)
      depth += 1
    end
    depth
  end

  def root?
    parent_comment_id.nil?
  end

  def can_have_replies?
    depth < MAX_DEPTH
  end

  private

  def inherit_post_from_parent
    return if post_id.present?
    self.post_id = parent_comment.post_id if parent_comment.present?
  end

  def parent_comment_belongs_to_same_post
    return if parent_comment.nil?
    return if parent_comment.post_id == post_id

    errors.add(:parent_comment, "must belong to the same post")
  end

  def parent_comment_within_max_depth
    return if parent_comment.nil?
    return if parent_comment.depth < MAX_DEPTH

    errors.add(:parent_comment, "can't be nested deeper than #{MAX_DEPTH} levels")
  end
end
