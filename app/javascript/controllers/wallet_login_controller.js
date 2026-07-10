import { Controller } from "@hotwired/stimulus"
import { createProvider } from "providers"

export default class extends Controller {
  static targets = ["walletAddress", "connectButton", "submitButton", "status", "providerButton"]
  static values = { provider: { type: String, default: "browser" } }

  connect() {
    this.setStatus("")
    this.provider = createProvider(this.providerValue)
    this.highlightProvider()
  }

  async selectProvider(event) {
    const key = event.currentTarget.dataset.providerKey
    if (key === this.providerValue) return

    let newProvider
    try {
      newProvider = createProvider(key)
    } catch (error) {
      this.setStatus(`Failed to switch: ${error.message}`, "error")
      return
    }

    if (this.provider && typeof this.provider.disconnect === "function") {
      await this.provider.disconnect()
    }

    this.provider = newProvider
    this.providerValue = key
    this.highlightProvider()
    this.walletAddressTarget.value = ""
    this.setStatus(`Switched to ${this.provider.name}.`)
  }

  highlightProvider() {
    this.providerButtonTargets.forEach(btn => {
      const isActive = btn.dataset.providerKey === this.providerValue
      btn.classList.toggle("provider-active", isActive)
      btn.classList.toggle("provider-inactive", !isActive)
    })
  }

  async connectWallet(event) {
    event.preventDefault()
    this.setBusy(true)
    this.setStatus("")

    try {
      const { address } = await this.provider.connect()
      this.walletAddressTarget.value = address
      this.setStatus(`Connected with ${this.provider.name}.`)
    } catch (error) {
      this.setStatus(error.message || "Connection failed.", "error")
    } finally {
      this.setBusy(false)
    }
  }

  async submit(event) {
    event.preventDefault()

    const walletAddress = this.walletAddressTarget.value.trim()
    if (!walletAddress) {
      this.setStatus("Enter a wallet address or connect first.", "error")
      return
    }

    this.setBusy(true)

    try {
      const challenge = await this.postJson("/session/nonce", { wallet_address: walletAddress })
      const signature = await this.provider.personalSign(challenge.message, challenge.wallet_address)

      await this.postJson("/session", {
        wallet_address: challenge.wallet_address,
        nonce: challenge.nonce,
        signature
      })

      this.setStatus("Signed in.")
      window.location.reload()
    } catch (error) {
      this.setStatus(error.message || "Sign in failed.", "error")
    } finally {
      this.setBusy(false)
    }
  }

  async postJson(url, body) {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken
      },
      body: JSON.stringify(body)
    })

    const data = await response.json().catch(() => ({}))
    if (!response.ok) {
      throw new Error(data.error || (data.errors || []).join(", ") || "Request failed.")
    }

    return data
  }

  setBusy(isBusy) {
    this.connectButtonTarget.disabled = isBusy
    this.submitButtonTarget.disabled = isBusy
  }

  setStatus(message, tone = "default") {
    this.statusTarget.textContent = message
    this.statusTarget.dataset.tone = tone
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content
  }
}
