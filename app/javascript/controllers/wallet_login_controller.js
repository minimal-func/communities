import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["walletAddress", "connectButton", "submitButton", "status"]

  connect() {
    this.setStatus("")
  }

  async connectWallet(event) {
    event.preventDefault()

    if (!window.ethereum) {
      this.setStatus("No browser wallet detected.", "error")
      return
    }

    this.setBusy(true)

    try {
      const accounts = await window.ethereum.request({ method: "eth_requestAccounts" })
      this.walletAddressTarget.value = accounts[0] || ""
      this.setStatus("Wallet connected.")
    } catch (error) {
      this.setStatus(error.message || "Wallet connection failed.", "error")
    } finally {
      this.setBusy(false)
    }
  }

  async submit(event) {
    event.preventDefault()

    const walletAddress = this.walletAddressTarget.value.trim()
    if (!walletAddress) {
      this.setStatus("Enter a wallet address.", "error")
      return
    }

    if (!window.ethereum) {
      this.setStatus("No browser wallet detected.", "error")
      return
    }

    this.setBusy(true)

    try {
      const challenge = await this.postJson("/session/nonce", { wallet_address: walletAddress })
      const signature = await window.ethereum.request({
        method: "personal_sign",
        params: [challenge.message, challenge.wallet_address]
      })

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
