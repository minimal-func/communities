# frozen_string_literal: true

ActiveAdmin.register AdminUser do
  menu priority: 7, label: "Admins"

  actions :index, :show, :new, :create, :edit, :update, :destroy

  permit_params :email, :password, :password_confirmation

  index title: "Admins" do
    id_column
    column :email
    column :created_at
    column :updated_at
    actions
  end

  filter :email
  filter :created_at

  form do |f|
    f.inputs "Admin details" do
      f.input :email
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end
end