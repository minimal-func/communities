import { Controller } from "@hotwired/stimulus"
import { Editor } from "@tiptap/core"
import StarterKit from "@tiptap/starter-kit"
import Placeholder from "@tiptap/extension-placeholder"
import Image from "@tiptap/extension-image"
import Link from "@tiptap/extension-link"
import { SlashMenu } from "lib/slash_menu"
import { Embed } from "lib/embed_extension"

export default class extends Controller {
  static targets = ["editor", "input", "fileInput"]
  static values = {
    placeholder: { type: String, default: "Start typing..." },
  }

  connect() {
    this.editor = new Editor({
      element: this.editorTarget,
      extensions: [
        StarterKit.configure({
          link: false,
        }),
        Placeholder.configure({
          placeholder: this.placeholderValue,
        }),
        Image.configure({
          inline: true,
        }),
        Link.configure({
          openOnClick: false,
          HTMLAttributes: {
            class: "editor-link",
          },
        }),
        SlashMenu,
        Embed,
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
    this.setupFileInput()
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

  setupFileInput() {
    this.fileInputTarget.addEventListener("change", (e) => {
      const file = e.target.files[0]
      if (file) this.uploadImage(file)
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
      case "link": this.toggleLink(); break
      case "image": this.addImage(); break
      case "embed": this.addEmbed(); break
    }
  }

  toggleLink() {
    const { editor } = this
    if (editor.isActive("link")) {
      const href = window.prompt("Edit URL", editor.getAttributes("link").href || "")
      if (href === null) return
      if (href === "") {
        editor.chain().focus().unsetLink().run()
      } else {
        editor.chain().focus().setLink({ href }).run()
      }
    } else {
      const href = window.prompt("Enter URL", "https://")
      if (href) {
        editor.chain().focus().setLink({ href }).run()
      }
    }
  }

  addImage() {
    this.fileInputTarget.value = ""
    this.fileInputTarget.click()
  }

  uploadImage(file) {
    const formData = new FormData()
    formData.append("image[file]", file)

    const btn = this.element.querySelector("[data-command='image']")
    const original = btn.innerHTML
    btn.disabled = true
    btn.innerHTML = "..."

    const csrfToken = document.querySelector("[name='csrf-token']")?.content

    fetch("/images", {
      method: "POST",
      body: formData,
      headers: { "Accept": "application/json", "X-CSRF-Token": csrfToken },
    })
      .then((res) => {
        if (!res.ok) return res.json().then((d) => { throw new Error(d.errors?.join(", ") || "Upload failed") })
        return res.json()
      })
      .then((data) => {
        this.editor.chain().focus().setImage({ src: data.url }).run()
      })
      .catch((err) => {
        alert(err.message)
      })
      .finally(() => {
        btn.innerHTML = original
        btn.disabled = false
      })
  }

  addEmbed() {
    const url = window.prompt("Enter URL to embed")
    if (url && url.trim()) {
      this.editor.chain().focus().setEmbed({ url: url.trim() }).run()
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
        case "link": isActive = this.editor.isActive("link"); break
        case "embed": isActive = this.editor.isActive("embed"); break
      }

      btn.classList.toggle("is-active", isActive)
    })
  }
}
