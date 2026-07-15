import { Controller } from "@hotwired/stimulus"
import { Editor } from "@tiptap/core"
import StarterKit from "@tiptap/starter-kit"
import Placeholder from "@tiptap/extension-placeholder"

export default class extends Controller {
  static targets = ["editor", "input"]
  static values = {
    placeholder: { type: String, default: "Start typing..." },
  }

  connect() {
    this.editor = new Editor({
      element: this.editorTarget,
      extensions: [
        StarterKit,
        Placeholder.configure({
          placeholder: this.placeholderValue,
        }),
      ],
      editorProps: {
        attributes: {
          class: "tiptap-editor",
        },
      },
      onUpdate: ({ editor }) => {
        this.syncInput(editor)
        this.updateToolbar()
      },
      onSelectionUpdate: ({ editor }) => {
        this.updateToolbar()
      },
    })
    this.syncInput(this.editor)
    this.setupToolbar()
  }

  disconnect() {
    this.editor?.destroy()
  }

  syncInput(editor) {
    this.inputTarget.value = editor.isEmpty ? "" : editor.getHTML()
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  setupToolbar() {
    this.element.querySelectorAll("[data-command]").forEach((btn) => {
      btn.addEventListener("mousedown", (e) => {
        e.preventDefault()
        this.executeCommand(btn)
      })
    })
  }

  executeCommand(btn) {
    const command = btn.dataset.command
    const level = btn.dataset.level
    const chain = this.editor.chain().focus()

    switch (command) {
      case "bold": chain.toggleBold().run(); break
      case "italic": chain.toggleItalic().run(); break
      case "underline": chain.toggleUnderline().run(); break
      case "strike": chain.toggleStrike().run(); break
      case "heading": chain.toggleHeading({ level: parseInt(level) }).run(); break
      case "bulletList": chain.toggleBulletList().run(); break
      case "orderedList": chain.toggleOrderedList().run(); break
      case "blockquote": chain.toggleBlockquote().run(); break
      case "codeBlock": chain.toggleCodeBlock().run(); break
      case "horizontalRule": chain.setHorizontalRule().run(); break
    }
  }

  updateToolbar() {
    this.element.querySelectorAll("[data-command]").forEach((btn) => {
      const command = btn.dataset.command
      const level = btn.dataset.level
      let isActive = false

      switch (command) {
        case "bold": isActive = this.editor.isActive("bold"); break
        case "italic": isActive = this.editor.isActive("italic"); break
        case "underline": isActive = this.editor.isActive("underline"); break
        case "strike": isActive = this.editor.isActive("strike"); break
        case "heading": isActive = this.editor.isActive("heading", { level: parseInt(level) }); break
        case "bulletList": isActive = this.editor.isActive("bulletList"); break
        case "orderedList": isActive = this.editor.isActive("orderedList"); break
        case "blockquote": isActive = this.editor.isActive("blockquote"); break
        case "codeBlock": isActive = this.editor.isActive("codeBlock"); break
        case "horizontalRule": isActive = this.editor.isActive("horizontalRule"); break
      }

      btn.classList.toggle("is-active", isActive)
    })
  }
}
