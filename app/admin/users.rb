# frozen_string_literal: true

ActiveAdmin.register Member, as: "User" do
  actions :index, :new, :create
  permit_params :wallet_address, :admin

  menu priority: 2, label: "Users"

  index title: "Users" do
    id_column
    column :wallet_address
    column("Role") { |member| member.admin? ? "Admin" : "Member" }
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
    f.actions
  end
end
