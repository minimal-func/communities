class CreateImages < ActiveRecord::Migration[8.1]
  def change
    create_table :images do |t|
      t.references :author_member, null: false, foreign_key: { to_table: :members }

      t.timestamps
    end
  end
end
