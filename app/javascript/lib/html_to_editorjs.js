export function htmlToEditorjs(html) {
  const doc = new DOMParser().parseFromString(html, "text/html")
  const blocks = []
  walk(doc.body, blocks)
  return { blocks }
}

function walk(root, blocks) {
  Array.from(root.childNodes).forEach((node) => {
    if (node.nodeType === Node.TEXT_NODE) {
      const text = node.textContent.trim()
      if (text) blocks.push(paragraphBlock(escapeHtml(text)))
      return
    }
    if (node.nodeType !== Node.ELEMENT_NODE) return

    const tag = node.tagName.toLowerCase()

    switch (tag) {
      case "h1":
      case "h2":
      case "h3":
      case "h4":
      case "h5":
      case "h6":
        blocks.push({ type: "header", data: { text: node.innerHTML.trim(), level: parseInt(tag[1], 10) } })
        break
      case "p":
        blocks.push(paragraphBlock(node.innerHTML.trim()))
        break
      case "ul":
      case "ol":
        blocks.push({
          type: "list",
          data: { style: tag === "ul" ? "unordered" : "ordered", items: listItems(node) },
        })
        break
      case "blockquote":
        blocks.push({ type: "quote", data: { text: node.innerHTML.trim(), caption: "", alignment: "left" } })
        break
      case "pre":
        blocks.push({ type: "code", data: { code: node.textContent } })
        break
      case "hr":
        blocks.push({ type: "delimiter" })
        break
      case "img":
        blocks.push({
          type: "image",
          data: { file: { url: node.getAttribute("src") || "" }, caption: node.getAttribute("alt") || "" },
        })
        break
      case "div":
        handleDiv(node, blocks)
        break
      default:
        const text = node.textContent.trim()
        if (text) blocks.push(paragraphBlock(node.innerHTML.trim()))
        break
    }
  })
}

function handleDiv(node, blocks) {
  if (node.hasAttribute("data-embed")) {
    const url = node.getAttribute("data-embed")
    if (node.getAttribute("data-embed-type") === "youtube") {
      const videoId = extractYoutubeId(url)
      if (videoId) {
        blocks.push({
          type: "embed",
          data: {
            service: "youtube",
            source: url,
            embed: `https://www.youtube.com/embed/${videoId}`,
            width: 580,
            height: 326,
            caption: "",
          },
        })
        return
      }
    }
    blocks.push(paragraphBlock(`<a href="${escapeAttr(url)}" target="_blank">${escapeHtml(url)}</a>`))
    return
  }
  walk(node, blocks)
}

function listItems(node) {
  return Array.from(node.querySelectorAll(":scope > li")).map((li) => {
    const nested = li.querySelector(":scope > ul, :scope > ol")
    if (!nested) return li.innerHTML.trim()
    nested.remove()
    return { content: li.innerHTML.trim(), items: listItems(nested) }
  })
}

function paragraphBlock(text) {
  return { type: "paragraph", data: { text } }
}

function extractYoutubeId(url) {
  const match = String(url).match(/(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})/)
  return match ? match[1] : null
}

function escapeHtml(text) {
  return String(text).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
}

function escapeAttr(text) {
  return String(text).replace(/&/g, "&amp;").replace(/"/g, "&quot;")
}
