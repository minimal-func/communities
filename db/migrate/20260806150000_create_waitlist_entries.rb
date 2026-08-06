class CreateWaitlistEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :waitlist_entries do |t|
      t.string :wallet_address, null: false
      t.string :status, default: "pending", null: false
      t.references :approved_by_admin_user, foreign_key: { to_table: :admin_users }
      t.references :accepted_member, foreign_key: { to_table: :members }
      t.datetime :approved_at
      t.datetime :rejected_at
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :waitlist_entries, :wallet_address, unique: true
    add_index :waitlist_entries, :status
  end
end
