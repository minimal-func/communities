module ApplicationHelper
  ALLOWED_TAGS = %w(h1 h2 h3 h4 h5 h6 p ul ol li pre code blockquote hr br strong em a b i s u del ins mark sub sup img).freeze
  ALLOWED_ATTRS = %w(href target rel src alt class).freeze

  def render_post_body(body)
    return unless body.present?
    if body.match?(/<[a-z][\s\S]*>/i)
      sanitize(body, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRS)
    else
      content_tag(:p, body, class: "body-text")
    end
  end
end
