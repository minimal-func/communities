import { Extension } from "@tiptap/core"
import { Plugin, PluginKey } from "@tiptap/pm/state"

const blockItems = [
  {
    title: "Text",
    icon: "T",
    description: "Plain paragraph",
    command: (editor) => editor.chain().focus().clearNodes().run(),
  },
  {
    title: "Heading 1",
    icon: "H1",
    description: "Big section heading",
    command: (editor) => editor.chain().focus().toggleHeading({ level: 1 }).run(),
  },
  {
    title: "Heading 2",
    icon: "H2",
    description: "Medium section heading",
    command: (editor) => editor.chain().focus().toggleHeading({ level: 2 }).run(),
  },
  {
    title: "Heading 3",
    icon: "H3",
    description: "Small section heading",
    command: (editor) => editor.chain().focus().toggleHeading({ level: 3 }).run(),
  },
  {
    title: "Bullet List",
    icon: "\u2022",
    description: "Create a bullet list",
    command: (editor) => editor.chain().focus().toggleBulletList().run(),
  },
  {
    title: "Numbered List",
    icon: "1.",
    description: "Create a numbered list",
    command: (editor) => editor.chain().focus().toggleOrderedList().run(),
  },
  {
    title: "Blockquote",
    icon: "\u201C",
    description: "Quote text",
    command: (editor) => editor.chain().focus().toggleBlockquote().run(),
  },
  {
    title: "Code Block",
    icon: "{ }",
    description: "Code with syntax highlighting",
    command: (editor) => editor.chain().focus().toggleCodeBlock().run(),
  },
  {
    title: "Divider",
    icon: "\u2014",
    description: "Horizontal divider",
    command: (editor) => editor.chain().focus().setHorizontalRule().run(),
  },
  {
    title: "Embed",
    icon: "\u25B6",
    description: "YouTube video or link preview",
    command: (editor) => {
      const url = window.prompt("Enter URL to embed")
      if (url && url.trim()) {
        editor.chain().focus().setEmbed({ url: url.trim() }).run()
      }
    },
  },
]

function computeMenuPosition(view, menu) {
  const coords = view.coordsAtPos(view.state.selection.from)
  if (!coords) return
  const menuWidth = 260
  let left = Math.max(10, coords.left - 8)
  if (left + menuWidth > window.innerWidth - 10) {
    left = window.innerWidth - menuWidth - 10
  }
  menu.style.left = `${left}px`
  menu.style.top = `${Math.max(4, coords.bottom + 4)}px`
}

export const SlashMenu = Extension.create({
  name: "slashMenu",

  addStorage() {
    return {
      visible: false,
      search: "",
      selectedIndex: 0,
      menuElement: null,
    }
  },

  onBeforeCreate() {
    const menu = document.createElement("div")
    menu.className = "slash-menu"
    menu.style.display = "none"
    this.storage.menuElement = menu
  },

  addProseMirrorPlugins() {
    const ext = this

    return [
      new Plugin({
        key: new PluginKey("slashMenu"),

        view(view) {
          const parent = view.dom.parentNode
          const menu = ext.storage.menuElement
          if (menu && parent) {
            parent.appendChild(menu)
          }

          return {
            update(view) {
              if (ext.storage.visible) {
                computeMenuPosition(view, ext.storage.menuElement)
              }
            },
            destroy() {
              ext.storage.menuElement?.remove()
            },
          }
        },

        props: {
          handleClick(view) {
            if (ext.storage.visible) {
              ext.closeMenu()
              return true
            }
            return false
          },

          handleKeyDown(view, event) {
            const { storage } = ext

            if (event.key === "Escape") {
              if (storage.visible) {
                ext.closeMenu()
                event.preventDefault()
                return true
              }
              return false
            }

            if (storage.visible) {
              const items = ext.getFilteredItems()

              if (event.key === "ArrowDown") {
                storage.selectedIndex = Math.min(storage.selectedIndex + 1, items.length - 1)
                ext.renderMenu(view)
                event.preventDefault()
                return true
              }

              if (event.key === "ArrowUp") {
                storage.selectedIndex = Math.max(storage.selectedIndex - 1, 0)
                ext.renderMenu(view)
                event.preventDefault()
                return true
              }

              if (event.key === "Enter" || event.key === "Tab") {
                const item = items[storage.selectedIndex]
                if (item) {
                  ext.executeCommand(item)
                  event.preventDefault()
                  return true
                }
                return false
              }

              if (event.key === "Backspace") {
                if (storage.search.length > 0) {
                  storage.search = storage.search.slice(0, -1)
                  storage.selectedIndex = 0
                  ext.renderMenu(view)
                  event.preventDefault()
                  return true
                }
                ext.closeMenu()
                event.preventDefault()
                return true
              }

              if (event.key.length === 1 && !event.ctrlKey && !event.metaKey) {
                storage.search += event.key
                storage.selectedIndex = 0
                ext.renderMenu(view)
                event.preventDefault()
                return true
              }

              return false
            }

            if (event.key === "/" && !event.shiftKey && !event.ctrlKey && !event.metaKey) {
              const { $from } = view.state.selection
              const parentOffset = $from.parentOffset

              if (parentOffset === 0 || $from.parent.textBetween(parentOffset - 1, parentOffset) === " ") {
                storage.visible = true
                storage.search = ""
                storage.selectedIndex = 0

                queueMicrotask(() => {
                  ext.renderMenu(view)
                  view.focus()
                })

                event.preventDefault()
                return true
              }
            }

            return false
          },
        },
      }),
    ]
  },

  getFilteredItems() {
    if (!this.storage.search) return blockItems
    const q = this.storage.search.toLowerCase()
    return blockItems.filter(
      (item) =>
        item.title.toLowerCase().includes(q) ||
        item.description.toLowerCase().includes(q)
    )
  },

  renderMenu(view) {
    const menu = this.storage.menuElement
    if (!menu) return

    const items = this.getFilteredItems()
    menu.innerHTML = ""

    if (items.length === 0) {
      const empty = document.createElement("div")
      empty.className = "slash-menu-empty"
      empty.textContent = "No results"
      menu.appendChild(empty)
    } else {
      items.forEach((item, index) => {
        const btn = document.createElement("button")
        btn.type = "button"
        btn.className = "slash-menu-item"
        if (index === this.storage.selectedIndex) btn.classList.add("active")
        btn.setAttribute("data-index", index)
        btn.innerHTML = `
          <span class="slash-menu-icon">${item.icon}</span>
          <span class="slash-menu-label">${item.title}</span>
          <span class="slash-menu-desc">${item.description}</span>
        `
        btn.addEventListener("mousedown", (e) => {
          e.preventDefault()
          this.executeCommand(item)
        })
        menu.appendChild(btn)
      })
    }

    menu.style.display = "block"
    computeMenuPosition(view, menu)
  },

  executeCommand(item) {
    this.closeMenu()
    item.command(this.editor)
    this.editor.view?.focus()
  },

  closeMenu() {
    this.storage.visible = false
    this.storage.search = ""
    this.storage.selectedIndex = 0
    this.storage.menuElement.style.display = "none"
  },
})
