class CreateReports < ActiveRecord::Migration[8.1]
  def change
    create_table :reports do |t|
      t.references :reporter_member, null: false, foreign_key: { to_table: :members }
      t.references :reportable, polymorphic: true, null: false
      t.text :reason, null: false
      t.string :status, default: "pending", null: false
      t.references :resolved_by_member, foreign_key: { to_table: :members }
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :reports, :status
  end
end
