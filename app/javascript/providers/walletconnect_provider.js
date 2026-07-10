const CONNECT_TIMEOUT_MS = 30_000

function withTimeout(promise, ms, label) {
  return Promise.race([
    promise,
    new Promise((_, reject) =>
      setTimeout(() => reject(new Error(`${label} timed out. Please try again.`)), ms)
    ),
  ])
}

let sdkCache = null
let unhandledHandlerInstalled = false

function installUnhandledRejectionGuard() {
  if (unhandledHandlerInstalled) return
  unhandledHandlerInstalled = true
  window.addEventListener("unhandledrejection", (event) => {
    const msg = event.reason?.message || String(event.reason)
    if (msg.includes("No matching key")) {
      event.preventDefault()
    }
  })
}

async function loadSdk() {
  if (sdkCache) return sdkCache
  sdkCache = await withTimeout(
    import("https://cdn.jsdelivr.net/npm/@walletconnect/ethereum-provider@2.11.0/+esm"),
    CONNECT_TIMEOUT_MS,
    "WalletConnect SDK load"
  )
  return sdkCache
}

export default class WalletConnectProvider {
  #provider = null

  get name() { return "WalletConnect" }
  get key() { return "walletconnect" }

  async connect() {
    const projectId = this.projectId
    if (!projectId) {
      throw new Error("WalletConnect project ID is not configured. Set it via <meta name=\"walletconnect-project-id\"> or ask the admin.")
    }

    let EthereumProvider
    try {
      const mod = await loadSdk()
      EthereumProvider = mod.EthereumProvider
    } catch (e) {
      sdkCache = null
      throw new Error(e.message || "Failed to load WalletConnect SDK. Check your internet connection and try again.")
    }

    await this.#teardown()

    this.#provider = await withTimeout(
      EthereumProvider.init({
        projectId,
        showQrModal: true,
        chains: [1],
        optionalChains: [1, 137, 42161, 10, 8453],
      }),
      CONNECT_TIMEOUT_MS,
      "WalletConnect init"
    )

    this.#provider.on("disconnect", () => { this.#provider = null })
    this.#provider.on("session_delete", () => { this.#provider = null })
    this.#provider.on("session_expire", () => { this.#provider = null })

    installUnhandledRejectionGuard()

    await withTimeout(
      this.#provider.connect(),
      CONNECT_TIMEOUT_MS,
      "WalletConnect connect"
    )

    const accounts = this.#provider.accounts
    if (!accounts || accounts.length === 0) {
      await this.#teardown()
      throw new Error("No accounts returned from WalletConnect. Please try again.")
    }
    return { address: accounts[0] }
  }

  async personalSign(message, address) {
    if (!this.#provider) throw new Error("WalletConnect is not connected.")
    const hexMessage = "0x" + Array.from(new TextEncoder().encode(message), b => b.toString(16).padStart(2, "0")).join("")
    return this.#provider.request({
      method: "personal_sign",
      params: [hexMessage, address]
    })
  }

  async disconnect() {
    await this.#teardown()
  }

  async #teardown() {
    if (this.#provider) {
      try { await this.#provider.disconnect() } catch {}
      this.#provider = null
    }
  }

  get projectId() {
    return document.querySelector('meta[name="walletconnect-project-id"]')?.content || ""
  }
}
