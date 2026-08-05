module Sluggable
  extend ActiveSupport::Concern

  class_methods do
    def slug_scope(*columns)
      @slug_scope_columns = columns
    end

    def slug_scope_columns
      @slug_scope_columns || []
    end
  end

  included do
    before_validation :generate_slug, on: :create
  end

  def to_param
    slug
  end

  private

  def generate_slug
    return if slug.present?

    base = base_slug
    return if base.blank?

    candidate = base
    i = 1
    while self.class.exists?(self.class.slug_scope_columns.to_h { |column| [ column, send(column) ] }.merge(slug: candidate))
      i += 1
      candidate = "#{base}-#{i}"
    end
    self.slug = candidate
  end

  def base_slug
    raise NotImplementedError
  end
end
