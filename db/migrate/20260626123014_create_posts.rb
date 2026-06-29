class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.references :community_thread, null: false, foreign_key: true
      t.references :author_member, null: false, foreign_key: { to_table: :members }
      t.text :body, null: false

      t.timestamps
    end
  end
end
