class Image < ApplicationRecord
  belongs_to :author_member, class_name: "Member"

  has_one_attached :file

  validate :validate_file

  private

  def validate_file
    return errors.add(:file, "must be attached") unless file.attached?

    if file.blob.byte_size > 10.megabytes
      errors.add(:file, "must be less than 10 MB")
    end

    unless file.blob.content_type.in?(%w[image/png image/jpeg image/gif image/webp image/svg+xml])
      errors.add(:file, "must be a PNG, JPEG, GIF, WebP, or SVG")
    end
  end
end
