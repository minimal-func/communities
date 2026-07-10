import BrowserProvider from "providers/browser_provider"
import WalletConnectProvider from "providers/walletconnect_provider"
import LedgerProvider from "providers/ledger_provider"

const registry = {
  browser: BrowserProvider,
  walletconnect: WalletConnectProvider,
  ledger: LedgerProvider,
}

export function createProvider(key) {
  const ProviderClass = registry[key]
  if (!ProviderClass) {
    throw new Error(`Unknown wallet provider: ${key}`)
  }
  return new ProviderClass()
}

export const PROVIDER_KEYS = Object.keys(registry)
