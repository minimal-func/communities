class AddEditorjsContentColumns < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :body_json, :jsonb
    add_column :comments, :body_json, :jsonb
    add_column :communities, :description_json, :jsonb
  end
end
