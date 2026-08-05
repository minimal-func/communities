class AddBodyJsonToCommunityThreads < ActiveRecord::Migration[8.1]
  def change
    add_column :community_threads, :body_json, :jsonb
  end
end
