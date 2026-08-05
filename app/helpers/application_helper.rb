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

  def render_rich_content(json_value, legacy_html)
    if editorjs_json?(json_value)
      render_editorjs_blocks(json_value)
    else
      render_post_body(legacy_html)
    end
  end

  def render_editorjs_blocks(json_data)
    return "".html_safe if json_data.blank?

    blocks = json_data.is_a?(String) ? JSON.parse(json_data)["blocks"] : json_data["blocks"]
    return "".html_safe if blocks.blank?

    blocks.map { |block| render_editorjs_block(block) }.join.html_safe
  rescue JSON::ParserError
    "".html_safe
  end

  def editorjs_json?(value)
    return false if value.blank?

    json = value.is_a?(String) ? JSON.parse(value) : value
    json.is_a?(Hash) && json["blocks"].is_a?(Array)
  rescue JSON::ParserError
    false
  end

  private

  def render_editorjs_block(block)
    case block["type"]
    when "header"    then content_tag("h#{block.dig("data", "level").to_i.clamp(1, 6)}", editorjs_sanitize(block.dig("data", "text")))
    when "paragraph" then content_tag(:p, editorjs_sanitize(block.dig("data", "text")))
    when "list"      then render_editorjs_list(block)
    when "checklist" then render_editorjs_checklist(block)
    when "quote"     then render_editorjs_quote(block)
    when "code"      then content_tag(:pre) { content_tag(:code, block.dig("data", "code").to_s) }
    when "image"     then render_editorjs_image(block)
    when "table"     then render_editorjs_table(block)
    when "delimiter" then content_tag(:hr)
    when "warning"   then render_editorjs_warning(block)
    when "raw"       then sanitize(block.dig("data", "html").to_s, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRS)
    when "embed"     then render_editorjs_embed(block)
    else ""
    end
  end

  def editorjs_sanitize(text)
    sanitize(text.to_s, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRS)
  end

  def render_editorjs_list(block)
    style = block.dig("data", "style") == "ordered" ? :ol : :ul
    content_tag(style) { render_editorjs_list_items(block.dig("data", "items")) }
  end

  def render_editorjs_list_items(items)
    Array(items).map do |item|
      if item.is_a?(Hash)
        content = editorjs_sanitize(item["content"])
        content += content_tag(:ul) { render_editorjs_list_items(item["items"]) } if item["items"].present?
        content_tag(:li, content)
      else
        content_tag(:li, editorjs_sanitize(item))
      end
    end.join.html_safe
  end

  def render_editorjs_checklist(block)
    content_tag(:div, class: "editorjs-checklist") do
      Array(block.dig("data", "items")).map do |item|
        checked = item["checked"]
        content_tag(:div, class: "checklist-item #{'checklist-item--checked' if checked}") do
          content_tag(:span, class: "checklist-item__checkbox") { checked ? "✓" : "" } +
            " " + content_tag(:span, editorjs_sanitize(item["text"]), class: "checklist-item__text")
        end
      end.join.html_safe
    end
  end

  def render_editorjs_quote(block)
    content_tag(:figure) do
      content_tag(:blockquote, editorjs_sanitize(block.dig("data", "text"))) +
        (block.dig("data", "caption").present? ? content_tag(:figcaption, editorjs_sanitize(block.dig("data", "caption"))) : "".html_safe)
    end
  end

  def render_editorjs_image(block)
    url = block.dig("data", "file", "url")
    caption = block.dig("data", "caption")
    content_tag(:figure) do
      image_tag(url, class: "img-fluid") +
        (caption.present? ? content_tag(:figcaption, editorjs_sanitize(caption)) : "".html_safe)
    end
  end

  def render_editorjs_table(block)
    content_tag(:table, class: "editorjs-table") do
      content_tag(:tbody) do
        Array(block.dig("data", "content")).map do |row|
          content_tag(:tr) do
            Array(row).map { |cell| content_tag(:td, editorjs_sanitize(cell)) }.join.html_safe
          end
        end.join.html_safe
      end
    end
  end

  def render_editorjs_warning(block)
    content_tag(:div, class: "editorjs-warning") do
      (block.dig("data", "title").present? ? content_tag(:strong, editorjs_sanitize(block.dig("data", "title"))) : "".html_safe) +
        content_tag(:p, editorjs_sanitize(block.dig("data", "message")))
    end
  end

  def render_editorjs_embed(block)
    embed_url = block.dig("data", "embed")
    source = block.dig("data", "source")
    caption = block.dig("data", "caption")
    content_tag(:figure) do
      if embed_url.present?
        content_tag(:div, class: "embed-youtube") do
          content_tag(:iframe, "", src: embed_url, frameborder: "0", allowfullscreen: "", allow: "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture")
        end
      elsif source.present?
        content_tag(:a, source, class: "embed-link-card", href: source, target: "_blank", rel: "noopener")
      end + (caption.present? ? content_tag(:figcaption, editorjs_sanitize(caption)) : "".html_safe)
    end
  end

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
