import { Node, mergeAttributes } from "@tiptap/core"
import { Plugin, PluginKey } from "@tiptap/pm/state"

function extractYoutubeId(url) {
  const patterns = [
    /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})/,
    /^([a-zA-Z0-9_-]{11})$/,
  ]
  for (const p of patterns) {
    const m = url.match(p)
    if (m) return m[1]
  }
  return null
}

function getDomain(url) {
  try {
    return new URL(url).hostname.replace(/^www\./, "")
  } catch {
    return url
  }
}

function detectType(url) {
  if (extractYoutubeId(url)) return "youtube"
  return "link"
}

export const Embed = Node.create({
  name: "embed",

  group: "block",

  atom: true,

  selectable: true,

  draggable: true,

  addAttributes() {
    return {
      url: { default: "" },
      type: { default: "link" },
      title: { default: "" },
    }
  },

  parseHTML() {
    return [
      {
        tag: "div[data-embed]",
        getAttrs: (el) => ({
          url: el.getAttribute("data-embed") || "",
          type: el.getAttribute("data-embed-type") || "link",
          title: el.getAttribute("data-embed-title") || "",
        }),
      },
    ]
  },

  renderHTML({ HTMLAttributes }) {
    const { url, type, title } = HTMLAttributes
    return [
      "div",
      mergeAttributes({
        "data-embed": url,
        "data-embed-type": type,
        "data-embed-title": title,
        class: "embed-node",
      }),
      [
        "div",
        { class: "embed-placeholder" },
        ["div", { class: "embed-icon" }, type === "youtube" ? "\u25B6" : "\uD83D\uDD17"],
        [
          "div",
          { class: "embed-info" },
          [
            "strong",
            title || url,
          ],
          [
            "span",
            { class: "embed-domain" },
            type === "youtube" ? "youtube.com" : getDomain(url),
          ],
        ],
      ],
    ]
  },

  addCommands() {
    return {
      setEmbed:
        (attrs) =>
        ({ commands }) => {
          return commands.insertContent({
            type: this.name,
            attrs: { ...attrs, type: detectType(attrs.url) },
          })
        },
    }
  },

  addNodeView() {
    return ({ node, getPos, editor }) => {
      const dom = document.createElement("div")
      dom.className = "embed-node-view"
      dom.setAttribute("data-embed-type", node.attrs.type)
      dom.contentEditable = false

      const { url, type, title } = node.attrs
      const domain = type === "youtube" ? "youtube.com" : getDomain(url)

      dom.innerHTML = `
        <div class="embed-preview">
          <div class="embed-icon">${type === "youtube" ? "\u25B6" : "\uD83D\uDD17"}</div>
          <div class="embed-details">
            <span class="embed-details-title">${this.escapeHtml(title || url)}</span>
            <span class="embed-details-domain">${this.escapeHtml(domain)}</span>
          </div>
        </div>
        <button class="embed-remove" title="Remove embed">&times;</button>
      `

      dom.querySelector(".embed-remove").addEventListener("mousedown", (e) => {
        e.preventDefault()
        const pos = getPos()
        if (typeof pos === "number") {
          editor.commands.deleteRange({ from: pos, to: pos + node.nodeSize })
        }
      })

      return { dom }
    }
  },

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  },

  addProseMirrorPlugins() {
    const ext = this
    return [
      new Plugin({
        key: new PluginKey("embedPaste"),
        props: {
          handlePaste(view, event) {
            const text = event.clipboardData?.getData("text/plain")
            if (!text) return false

            const trimmed = text.trim()
            if (!trimmed.startsWith("http://") && !trimmed.startsWith("https://")) return false

            const youtubeId = extractYoutubeId(trimmed)
            if (!youtubeId) return false

            event.preventDefault()
            const { schema } = view.state
            const node = schema.nodes.embed.create({
              url: trimmed,
              type: "youtube",
              title: "",
            })
            const tr = view.state.tr.replaceSelectionWith(node)
            view.dispatch(tr)
            return true
          },
        },
      }),
    ]
  },
})
