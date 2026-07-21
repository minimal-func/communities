# frozen_string_literal: true

ActiveAdmin.register Member, as: "User" do
  actions :index, :new, :create, :edit, :update
  permit_params :wallet_address, :admin,
    community_members_attributes: [:id, :community_id, :role, :_destroy]

  menu priority: 2, label: "Users"

  index title: "Users" do
    id_column
    column :wallet_address
    column("Role") { |member| member.admin? ? "Admin" : "Member" }
    column("Communities") { |member| member.member_communities.map(&:name).join(", ").presence || "—" }
    column("Last signed in") { |member| member.last_signed_in_at ? l(member.last_signed_in_at, format: :short) : "Never" }
    column :created_at
  end

  filter :wallet_address
  filter :admin
  filter :created_at

  form do |f|
    f.inputs "User details" do
      f.input :wallet_address
      f.input :admin
    end
    f.inputs "Community memberships" do
      f.has_many :community_members, allow_destroy: true, heading: "Memberships", new_record: "Add community membership" do |cmf|
        cmf.input :community, collection: Community.order(:name).map { |c| [c.name, c.id] }
        cmf.input :role, as: :select, collection: [["Member", "member"], ["Admin", "admin"]], include_blank: false
      end
    end
    f.actions
  end
end
