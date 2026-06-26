# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
if ENV["INITIAL_MEMBER_WALLET"].present?
  member = Member.find_or_create_by!(wallet_address: ENV["INITIAL_MEMBER_WALLET"])
  puts "Initial member wallet: #{member.wallet_address}"
end
