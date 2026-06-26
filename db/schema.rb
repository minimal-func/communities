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

ActiveRecord::Schema[8.1].define(version: 2026_06_26_000003) do
  create_table "members", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "invited_by_member_id"
    t.datetime "last_signed_in_at"
    t.datetime "updated_at", null: false
    t.string "wallet_address", null: false
    t.index ["invited_by_member_id"], name: "index_members_on_invited_by_member_id"
    t.index ["wallet_address"], name: "index_members_on_wallet_address", unique: true
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

  add_foreign_key "members", "members", column: "invited_by_member_id"
  add_foreign_key "wallet_invitations", "members", column: "accepted_member_id"
  add_foreign_key "wallet_invitations", "members", column: "invited_by_member_id"
end
