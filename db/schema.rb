# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_08_000000) do
  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.integer "author_member_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "post_id", null: false
    t.datetime "updated_at", null: false
    t.index ["author_member_id"], name: "index_comments_on_author_member_id"
    t.index ["post_id"], name: "index_comments_on_post_id"
  end

  create_table "communities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "created_by_member_id", null: false
    t.text "description"
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_member_id"], name: "index_communities_on_created_by_member_id"
    t.index ["slug"], name: "index_communities_on_slug", unique: true
  end

  create_table "community_members", force: :cascade do |t|
    t.integer "community_id", null: false
    t.datetime "created_at", null: false
    t.integer "member_id", null: false
    t.string "role", default: "member", null: false
    t.datetime "updated_at", null: false
    t.index ["community_id", "member_id"], name: "index_community_members_on_community_id_and_member_id", unique: true
    t.index ["community_id"], name: "index_community_members_on_community_id"
    t.index ["member_id"], name: "index_community_members_on_member_id"
  end

  create_table "community_threads", force: :cascade do |t|
    t.integer "author_member_id", null: false
    t.text "body"
    t.integer "community_id", null: false
    t.datetime "created_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["author_member_id"], name: "index_community_threads_on_author_member_id"
    t.index ["community_id"], name: "index_community_threads_on_community_id"
  end

  create_table "members", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.integer "invited_by_member_id"
    t.datetime "last_signed_in_at"
    t.datetime "updated_at", null: false
    t.string "wallet_address", null: false
    t.index ["invited_by_member_id"], name: "index_members_on_invited_by_member_id"
    t.index ["wallet_address"], name: "index_members_on_wallet_address", unique: true
  end

  create_table "posts", force: :cascade do |t|
    t.integer "author_member_id", null: false
    t.text "body", null: false
    t.integer "community_thread_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_member_id"], name: "index_posts_on_author_member_id"
    t.index ["community_thread_id"], name: "index_posts_on_community_thread_id"
  end

  create_table "wallet_invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.integer "accepted_member_id"
    t.datetime "created_at", null: false
    t.integer "invited_by_member_id", null: false
    t.datetime "updated_at", null: false
    t.string "wallet_address", null: false
    t.index ["accepted_member_id"], name: "index_wallet_invitations_on_accepted_member_id"
    t.index ["invited_by_member_id"], name: "index_wallet_invitations_on_invited_by_member_id"
    t.index ["wallet_address"], name: "index_wallet_invitations_on_wallet_address", unique: true
  end

  create_table "wallet_login_challenges", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "nonce", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.string "wallet_address", null: false
    t.index ["nonce"], name: "index_wallet_login_challenges_on_nonce", unique: true
    t.index ["wallet_address"], name: "index_wallet_login_challenges_on_wallet_address"
  end

  add_foreign_key "comments", "members", column: "author_member_id"
  add_foreign_key "comments", "posts"
  add_foreign_key "communities", "members", column: "created_by_member_id"
  add_foreign_key "community_members", "communities"
  add_foreign_key "community_members", "members"
  add_foreign_key "community_threads", "communities"
  add_foreign_key "community_threads", "members", column: "author_member_id"
  add_foreign_key "members", "members", column: "invited_by_member_id"
  add_foreign_key "posts", "community_threads"
  add_foreign_key "posts", "members", column: "author_member_id"
  add_foreign_key "wallet_invitations", "members", column: "accepted_member_id"
  add_foreign_key "wallet_invitations", "members", column: "invited_by_member_id"
end
