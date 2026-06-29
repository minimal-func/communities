class CreateCommunities < ActiveRecord::Migration[8.1]
  def change
    create_table :communities do |t|
      t.references :created_by_member, null: false, foreign_key: { to_table: :members }
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description

      t.timestamps
    end

    add_index :communities, :slug, unique: true
  end
end
