ActiveRecord::Schema[7.2].define(version: 2025_01_01_000001) do
  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "groupable_groups", force: :cascade do |t|
    t.string "name"
    t.string "auth_name"
    t.string "password_digest"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "active" ], name: "index_groupable_groups_on_active"
  end

  create_table "groupable_members", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "group_id", null: false
    t.integer "role", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "group_id" ], name: "index_groupable_members_on_group_id"
    t.index [ "user_id", "group_id" ], name: "index_groupable_members_on_user_id_and_group_id", unique: true
    t.index [ "user_id" ], name: "index_groupable_members_on_user_id"
  end

  create_table "groupable_invites", force: :cascade do |t|
    t.integer "group_id", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "code" ], name: "index_groupable_invites_on_code"
    t.index [ "created_at" ], name: "index_groupable_invites_on_created_at"
    t.index [ "group_id" ], name: "index_groupable_invites_on_group_id"
  end

  add_foreign_key "groupable_invites", "groupable_groups", column: "group_id"
  add_foreign_key "groupable_members", "groupable_groups", column: "group_id"
  add_foreign_key "groupable_members", "users"
end
