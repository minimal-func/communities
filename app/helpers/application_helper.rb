module ApplicationHelper
  ALLOWED_TAGS = %w(h1 h2 h3 h4 h5 h6 p ul ol li pre code blockquote hr br strong em a b i s u del ins mark sub sup img div span iframe).freeze
  ALLOWED_ATTRS = %w(href target rel src alt class data-embed data-embed-type data-embed-title frameborder allowfullscreen allow width height).freeze

  def render_post_body(body)
    return unless body.present?
    html = body.dup
    html = transform_embeds(html) if html.match?(/<div[^>]*data-embed=/)
    if html.match?(/<[a-z][\s\S]*>/i)
      sanitize(html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRS)
    else
      content_tag(:p, html, class: "body-text")
    end
  end

  private

  def transform_embeds(html)
    doc = Nokogiri::HTML.fragment(html)
    doc.css("div[data-embed]").each do |node|
      url = node["data-embed"]
      type = node["data-embed-type"]
      next if url.blank?

      if type == "youtube"
        video_id = extract_youtube_id(url)
        if video_id
          replacement = doc.document.create_element("div",
            class: "embed-youtube",
            dir: "ltr"
          )
          iframe = doc.document.create_element("iframe",
            src: "https://www.youtube.com/embed/#{video_id}",
            frameborder: "0",
            allowfullscreen: "",
            allow: "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
          )
          replacement.add_child(iframe)
          node.replace(replacement)
        end
      else
        domain = begin
          URI.parse(url).host&.sub(/\Awww\./, "")
        rescue StandardError
          url
        end
        replacement = doc.document.create_element("a",
          class: "embed-link-card",
          href: url,
          target: "_blank",
          rel: "noopener"
        )
        domain_el = doc.document.create_element("span", class: "embed-link-domain")
        domain_el.content = domain || url
        url_el = doc.document.create_element("span", class: "embed-link-url")
        url_el.content = url
        replacement.add_child(domain_el)
        replacement.add_child(url_el)
        node.replace(replacement)
      end
    end
    doc.to_html
  end

  def extract_youtube_id(url)
    patterns = [
      /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})/,
      /\A([a-zA-Z0-9_-]{11})\z/,
    ]
    patterns.each do |p|
      m = url.match(p)
      return m[1] if m
    end
    nil
  end
end
