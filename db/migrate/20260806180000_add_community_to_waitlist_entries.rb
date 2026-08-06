class AddCommunityToWaitlistEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :waitlist_entries, :community_name, :string
    add_column :waitlist_entries, :community_description, :text
    add_reference :waitlist_entries, :community, foreign_key: true
  end
end