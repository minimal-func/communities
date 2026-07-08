export default class LedgerProvider {
  get name() { return "Ledger" }
  get key() { return "ledger" }

  async connect() {
    if (typeof window.ethereum === "undefined") {
      throw new Error("Ledger Live extension not detected. Install it from https://ledger.com/live")
    }
    const accounts = await window.ethereum.request({ method: "eth_requestAccounts" })
    if (!accounts || accounts.length === 0) {
      throw new Error("No accounts returned from Ledger.")
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
