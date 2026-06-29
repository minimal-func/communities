class CreateCommunityThreads < ActiveRecord::Migration[8.1]
  def change
    create_table :community_threads do |t|
      t.references :community, null: false, foreign_key: true
      t.references :author_member, null: false, foreign_key: { to_table: :members }
      t.string :title, null: false
      t.text :body

      t.timestamps
    end
  end
end
