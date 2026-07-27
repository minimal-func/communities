class AddBannedAtToCommunityMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :community_members, :banned_at, :datetime
    add_column :community_members, :banned_by_member_id, :integer
    add_index :community_members, :banned_at
  end
end
