# frozen_string_literal: true

ActiveAdmin.register WaitlistEntry do
  menu priority: 3, label: "Waitlist & Invites"

  actions :index, :show, :destroy

  scope :all, default: true
  scope :pending
  scope :approved
  scope :rejected
  scope :accepted

  index title: "Waitlist & Invites" do
    id_column
    column :community_name
    column :community_description do |entry|
      if entry.community_description.present?
        truncate(entry.community_description, length: 60)
      else
        "—"
      end
    end
    column :wallet_address
    column("Proposed by wallet") { |entry| entry.accepted? ? "Yes" : "No" }
    column :status
    column("Approved by") { |entry| entry.approved_by_admin_user&.email || "—" }
    column("Community") { |entry| entry.community ? entry.community.name : "—" }
    column :created_at
    actions defaults: false do |entry|
      if entry.pending?
        link_to "Approve", approve_admin_waitlist_entry_path(entry), method: :post, class: "member_link"
        link_to "Reject", reject_admin_waitlist_entry_path(entry), method: :post, class: "member_link"
      end
      link_to "View", admin_waitlist_entry_path(entry)
      link_to "Delete", admin_waitlist_entry_path(entry), method: :delete, data: { confirm: "Delete this waitlist entry?" }
    end
  end

  show do
    attributes_table do
      row :id
      row :community_name
      row :community_description
      row :wallet_address
      row :status
      row :approved_by_admin_user
      row :approved_at
      row :rejected_at
      row :accepted_member
      row :accepted_at
      row :community
      row :created_at
      row :updated_at
    end

    if resource.pending?
      panel "Actions" do
        para button_to "Approve invitation", approve_admin_waitlist_entry_path(resource), method: :post, class: "button"
        para button_to "Reject invitation", reject_admin_waitlist_entry_path(resource), method: :post, class: "button button-red"
      end
    end
  end

  filter :wallet_address
  filter :status, as: :select, collection: WaitlistEntry::STATUSES
  filter :created_at

  member_action :approve, method: :post do
    resource.approve!(current_admin_user)
    redirect_to collection_path, notice: "Invitation for #{resource.wallet_address} approved."
  end

  member_action :reject, method: :post do
    resource.reject!(current_admin_user)
    redirect_to collection_path, notice: "Invitation for #{resource.wallet_address} rejected."
  end
end
