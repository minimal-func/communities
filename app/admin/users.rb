# frozen_string_literal: true

ActiveAdmin.register Member, as: "User" do
  actions :index, :new, :create
  permit_params :wallet_address, :admin, :community_id, :community_role

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
    f.inputs "Community membership" do
      f.input :community_id,
        as: :select,
        collection: Community.order(:name).map { |c| [c.name, c.id] },
        include_blank: "No community",
        label: "Community"
      f.input :community_role,
        as: :select,
        collection: [["Member", "member"], ["Admin", "admin"]],
        include_blank: true,
        label: "Role"
    end
    f.actions
  end

  after_create do |member|
    community_id = params[:member][:community_id]
    next if community_id.blank?

    role = params[:member][:community_role].presence || "member"
    member.community_members.create!(community_id: community_id, role: role)
  end
end
