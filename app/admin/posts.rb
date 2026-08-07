# frozen_string_literal: true

ActiveAdmin.register Post do
  menu priority: 6, label: "Posts"

  actions :index, :show, :new, :create, :edit, :update, :destroy

  permit_params :community_thread_id, :author_member_id, :body, :visibility

  index title: "Posts" do
    id_column
    column("Thread") { |post| post.community_thread&.title || "—" }
    column("Author") { |post| post.author_member&.wallet_address || "—" }
    column :body do |post|
      truncate(post.body.to_s.presence || post.body_json.to_json, length: 60)
    end
    column :visibility
    column("Comments") { |post| post.comments.count }
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :community_thread
      row :author_member
      row :body
      row :visibility
      row :slug
      row :created_at
      row :updated_at
    end
    panel "Comments" do
      table_for post.comments do
        column :body
        column :author_member
        column :created_at
      end
    end
  end

  filter :community_thread
  filter :author_member, collection: -> { Member.order(:created_at).map { |m| [m.wallet_address, m.id] } }
  filter :visibility, as: :select, collection: Post.visibility_options.values
  filter :created_at

  form do |f|
    f.inputs "Post details" do
      f.input :community_thread, collection: CommunityThread.order(:created_at).map { |t| [t.title, t.id] }, include_blank: false
      f.input :author_member, collection: Member.order(:created_at).map { |m| [m.wallet_address, m.id] }, include_blank: false
      f.input :body
      f.input :visibility, as: :select, collection: Post.visibility_options.values, include_blank: false
    end
    f.actions
  end
end