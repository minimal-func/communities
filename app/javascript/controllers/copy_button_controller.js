import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { copyText: String }

  copy() {
    navigator.clipboard.writeText(this.copyTextValue).then(() => {
      const original = this.element.textContent
      this.element.textContent = "Copied!"
      setTimeout(() => {
        this.element.textContent = original
      }, 1500)
    })
  }
}
