# frozen_string_literal: true

ActiveAdmin.register CommunityThread do
  menu priority: 5, label: "Threads"

  actions :index, :show, :new, :create, :edit, :update, :destroy

  permit_params :community_id, :author_member_id, :title, :body

  index title: "Threads" do
    id_column
    column :title
    column("Community") { |thread| thread.community&.name || "—" }
    column("Author") { |thread| thread.author_member&.wallet_address || "—" }
    column("Posts") { |thread| thread.posts.count }
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :community
      row :author_member
      row :title
      row :body
      row :slug
      row :created_at
      row :updated_at
    end
    panel "Posts" do
      table_for community_thread.posts do
        column :body
        column :author_member
        column :visibility
      end
    end
  end

  filter :community
  filter :title
  filter :author_member, collection: -> { Member.order(:created_at).map { |m| [m.wallet_address, m.id] } }
  filter :created_at

  form do |f|
    f.inputs "Thread details" do
      f.input :community, collection: Community.order(:name).map { |c| [c.name, c.id] }, include_blank: false
      f.input :author_member, collection: Member.order(:created_at).map { |m| [m.wallet_address, m.id] }, include_blank: false
      f.input :title
      f.input :body
    end
    f.actions
  end
end