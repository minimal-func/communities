class AddRequestedAtToCommunityMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :community_members, :requested_at, :datetime
  end
end
