class EthereumWallet
  ADDRESS_FORMAT = /\A0x[0-9a-fA-F]{40}\z/

  def self.normalize(address)
    address.to_s.strip.downcase
  end

  def self.valid_address?(address)
    normalize(address).match?(ADDRESS_FORMAT)
  end
end
