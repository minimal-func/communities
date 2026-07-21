class AddVisibilityToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :visibility, :string, default: "members", null: false
    add_index :posts, :visibility
  end
end
