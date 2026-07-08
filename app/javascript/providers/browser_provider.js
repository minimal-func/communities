export default class BrowserProvider {
  get name() { return "Browser Wallet" }
  get key() { return "browser" }

  async connect() {
    if (typeof window.ethereum === "undefined") {
      throw new Error("No browser wallet detected. Install MetaMask, Ledger Live, or another Ethereum wallet extension.")
    }
    const accounts = await window.ethereum.request({ method: "eth_requestAccounts" })
    if (!accounts || accounts.length === 0) {
      throw new Error("No accounts returned from wallet.")
    }
    return { address: accounts[0] }
  }

  async personalSign(message, address) {
    return window.ethereum.request({
      method: "personal_sign",
      params: [message, address]
    })
  }
}
