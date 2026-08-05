class AllowNullBodyForRichContent < ActiveRecord::Migration[8.1]
  def change
    change_column_null :posts, :body, true
    change_column_null :comments, :body, true
  end
end
