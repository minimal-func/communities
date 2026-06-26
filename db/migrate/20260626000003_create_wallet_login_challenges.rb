class CreateWalletLoginChallenges < ActiveRecord::Migration[8.1]
  def change
    create_table :wallet_login_challenges do |t|
      t.string :wallet_address, null: false
      t.string :nonce, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end

    add_index :wallet_login_challenges, :wallet_address
    add_index :wallet_login_challenges, :nonce, unique: true
  end
end
