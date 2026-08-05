import { Controller } from "@hotwired/stimulus"
import EditorJS from "@editorjs/editorjs"
import Header from "@editorjs/header"
import List from "@editorjs/list"
import ImageTool from "@editorjs/image"
import Quote from "@editorjs/quote"
import Code from "@editorjs/code"
import InlineCode from "@editorjs/inline-code"
import Table from "@editorjs/table"
import Marker from "@editorjs/marker"
import Warning from "@editorjs/warning"
import Checklist from "@editorjs/checklist"
import Delimiter from "@editorjs/delimiter"
import Raw from "@editorjs/raw"
import Embed from "@editorjs/embed"
import { htmlToEditorjs } from "lib/html_to_editorjs"

export default class extends Controller {
  static targets = ["holder", "input"]
  static values = {
    placeholder: { type: String, default: "Start typing..." },
    legacy: { type: String, default: "" },
  }

  connect() {
    this.holderTarget.innerHTML = ""
    this.editor = new EditorJS({
      holder: this.holderTarget,
      data: this.initialData(),
      placeholder: this.placeholderValue,
      minHeight: 180,
      tools: this.buildTools(),
      onChange: () => this.sync(),
    })
  }

  disconnect() {
    this.editor?.destroy()
    this.editor = null
  }

  initialData() {
    if (this.inputTarget.value && this.inputTarget.value !== "null") {
      try {
        return JSON.parse(this.inputTarget.value)
      } catch (error) {
        console.error("Invalid body_json, starting with a fresh editor.", error)
      }
    }
    if (this.legacyValue.trim()) {
      const converted = htmlToEditorjs(this.legacyValue)
      if (converted.blocks.length) return converted
    }
    return { time: Date.now(), blocks: [] }
  }

  async sync() {
    const data = await this.editor.save()
    this.inputTarget.value = this.isEmptyData(data) ? "" : JSON.stringify(data)
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  isEmptyData(data) {
    const blocks = data?.blocks || []
    if (!blocks.length) return true
    if (blocks.length === 1 && blocks[0].type === "paragraph" && !(blocks[0].data?.text || "").trim()) return true
    return false
  }

  buildTools() {
    const csrfToken = document.querySelector("[name='csrf-token']")?.getAttribute("content")

    return {
      header: { class: Header, inlineToolbar: true },
      paragraph: { inlineToolbar: true },
      list: {
        class: List,
        inlineToolbar: true,
        config: { defaultStyle: "unordered" },
      },
      checklist: { class: Checklist, inlineToolbar: true },
      quote: {
        class: Quote,
        inlineToolbar: true,
        config: { quotePlaceholder: "Enter a quote", captionPlaceholder: "Quote's author" },
      },
      warning: { class: Warning, inlineToolbar: true },
      marker: Marker,
      code: Code,
      inlineCode: InlineCode,
      delimiter: Delimiter,
      table: { class: Table, inlineToolbar: true },
      raw: Raw,
      embed: Embed,
      image: {
        class: ImageTool,
        config: {
          uploader: {
            async uploadByFile(file) {
              const formData = new FormData()
              formData.append("image[file]", file)

              const response = await fetch("/images", {
                method: "POST",
                headers: { "Accept": "application/json", "X-CSRF-Token": csrfToken },
                body: formData,
              })
              if (!response.ok) {
                const data = await response.json().catch(() => ({}))
                throw new Error(data.errors?.join(", ") || "Upload failed")
              }
              const data = await response.json()
              return { success: 1, file: { url: data.url } }
            },
            async uploadByUrl(url) {
              return { success: 1, file: { url } }
            },
          },
        },
      },
    }
  }
}
