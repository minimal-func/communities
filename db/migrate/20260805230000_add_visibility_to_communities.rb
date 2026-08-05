class AddVisibilityToCommunities < ActiveRecord::Migration[8.1]
  def change
    add_column :communities, :visibility, :string, default: "closed", null: false
    add_index :communities, :visibility
  end
end
