class CreateCommunityMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :community_members do |t|
      t.references :community, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.string :role, null: false, default: "member"

      t.timestamps
    end

    add_index :community_members, %i[community_id member_id], unique: true

    reversible do |dir|
      dir.up do
        Community.find_each do |community|
          CommunityMember.find_or_create_by!(community: community, member: community.created_by_member) do |cm|
            cm.role = "admin"
          end
        end
      end
    end
  end
end
