# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
admin_email = ENV.fetch("ADMIN_EMAIL", "admin@example.com")
admin_password = ENV.fetch("ADMIN_PASSWORD", "password123")

AdminUser.find_or_create_by!(email: admin_email) do |u|
  u.password = admin_password
end

puts "Admin user: #{admin_email} / #{admin_password}"

if ENV["INITIAL_MEMBER_WALLET"].present?
  member = Member.find_or_create_by!(wallet_address: ENV["INITIAL_MEMBER_WALLET"])
  member.update!(admin: true) if member.respond_to?(:admin?) && !member.admin?
  puts "Initial member wallet: #{member.wallet_address}"
end
