class ChangeWalletInvitationsUniqueIndex < ActiveRecord::Migration[8.1]
  def up
    remove_index :wallet_invitations, name: "index_wallet_invitations_on_wallet_address"
    add_index :wallet_invitations, [:community_id, :wallet_address], unique: true, name: "index_wallet_invitations_on_community_and_wallet"
  end

  def down
    remove_index :wallet_invitations, name: "index_wallet_invitations_on_community_and_wallet"
    add_index :wallet_invitations, :wallet_address, unique: true, name: "index_wallet_invitations_on_wallet_address"
  end
end
