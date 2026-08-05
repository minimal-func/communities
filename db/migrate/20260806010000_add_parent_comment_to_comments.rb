class AddParentCommentToComments < ActiveRecord::Migration[8.1]
  def change
    add_reference :comments, :parent_comment, foreign_key: { to_table: :comments }, null: true
  end
end
