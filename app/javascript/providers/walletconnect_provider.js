let cachedProvider = null

export default class WalletConnectProvider {
  get name() { return "WalletConnect" }
  get key() { return "walletconnect" }

  async connect() {
    const projectId = this.projectId
    if (!projectId) {
      throw new Error("WalletConnect project ID is not configured. Set it via <meta name=\"walletconnect-project-id\"> or ask the admin.")
    }

    let EthereumProvider
    try {
      const mod = await import("https://cdn.jsdelivr.net/npm/@walletconnect/ethereum-provider@2.11.0/+esm")
      EthereumProvider = mod.EthereumProvider
    } catch {
      throw new Error("Failed to load WalletConnect SDK. Check your internet connection and try again.")
    }

    if (!cachedProvider) {
      cachedProvider = await EthereumProvider.init({
        projectId,
        showQrModal: true,
        chains: [1],
        optionalChains: [1, 137, 42161, 10, 8453],
      })
    }

    if (!cachedProvider.connected) {
      await cachedProvider.connect()
    }

    const accounts = cachedProvider.accounts
    if (!accounts || accounts.length === 0) {
      throw new Error("No accounts returned from WalletConnect.")
    }
    return { address: accounts[0] }
  }

  async personalSign(message, address) {
    if (!cachedProvider) throw new Error("WalletConnect is not connected.")
    return cachedProvider.request({
      method: "personal_sign",
      params: [message, address]
    })
  }

  async disconnect() {
    if (cachedProvider) {
      try {
        await cachedProvider.disconnect()
      } catch {
        // ignore disconnect errors
      }
      cachedProvider = null
    }
  }

  get projectId() {
    return document.querySelector('meta[name="walletconnect-project-id"]')?.content || ""
  }
}
