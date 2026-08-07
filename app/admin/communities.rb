# frozen_string_literal: true

ActiveAdmin.register Community do
  menu priority: 4, label: "Communities"

  actions :index, :show, :new, :create, :edit, :update, :destroy

  permit_params :name, :slug, :description, :visibility, :created_by_member_id

  index title: "Communities" do
    id_column
    column :name
    column :slug
    column("Visibility") { |community| community.visibility.humanize }
    column("Created by") { |community| community.created_by_member&.wallet_address || "—" }
    column("Members") { |community| community.community_members.active.count }
    column("Threads") { |community| community.community_threads.count }
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :slug
      row :description
      row :visibility
      row :created_by_member
      row :created_at
      row :updated_at
    end
    panel "Members" do
      table_for community.community_members.active do
        column :member
        column :role
        column :created_at
      end
    end
    panel "Threads" do
      table_for community.community_threads do
        column :title
        column :author_member
      end
    end
  end

  filter :name
  filter :slug
  filter :visibility, as: :select, collection: Community::VISIBILITIES
  filter :created_at

  form do |f|
    f.inputs "Community details" do
      f.input :name
      f.input :slug
      f.input :description
      f.input :visibility, as: :select, collection: Community.visibility_options.values, include_blank: false
      f.input :created_by_member, collection: Member.order(:created_at).map { |m| [m.wallet_address, m.id] }, include_blank: false
    end
    f.actions
  end
end