class CreateWalletInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :wallet_invitations do |t|
      t.string :wallet_address, null: false
      t.references :invited_by_member, null: false, foreign_key: { to_table: :members }
      t.references :accepted_member, foreign_key: { to_table: :members }
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :wallet_invitations, :wallet_address, unique: true
  end
end
