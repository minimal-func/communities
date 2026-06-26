class CreateMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :members do |t|
      t.string :wallet_address, null: false
      t.references :invited_by_member, foreign_key: { to_table: :members }
      t.datetime :last_signed_in_at

      t.timestamps
    end

    add_index :members, :wallet_address, unique: true
  end
end
