class AddCommunityToWalletInvitations < ActiveRecord::Migration[8.1]
  def change
    add_reference :wallet_invitations, :community, null: true, foreign_key: true
    add_column :wallet_invitations, :community_role, :string
  end
end
