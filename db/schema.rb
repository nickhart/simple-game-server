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

ActiveRecord::Schema[7.1].define(version: 2025_04_07_033519) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "applications", force: :cascade do |t|
    t.string "name"
    t.string "api_key"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_applications_on_active"
    t.index ["api_key"], name: "index_applications_on_api_key", unique: true
  end

  create_table "game_configurations", force: :cascade do |t|
    t.bigint "game_id", null: false
    t.jsonb "state_schema", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_game_configurations_on_game_id"
  end

  create_table "game_players", force: :cascade do |t|
    t.bigint "game_session_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "player_id"
    t.index ["game_session_id"], name: "index_game_players_on_game_session_id"
    t.index ["player_id", "game_session_id"], name: "index_game_players_on_player_id_and_game_session_id", unique: true
  end

  create_table "game_sessions", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.integer "min_players", default: 2, null: false
    t.integer "max_players", default: 4, null: false
    t.integer "current_player_index"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "game_type", default: "default", null: false
    t.jsonb "state"
    t.string "name"
    t.uuid "creator_id"
    t.bigint "game_id"
  end

  create_table "games", force: :cascade do |t|
    t.string "name", null: false
    t.integer "min_players", null: false
    t.integer "max_players", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_games_on_name", unique: true
  end

  create_table "players", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "game_session_id"
    t.bigint "user_id"
    t.index ["game_session_id"], name: "index_players_on_game_session_id"
    t.index ["user_id"], name: "index_players_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "game_configurations", "games"
  add_foreign_key "game_players", "game_sessions"
  add_foreign_key "game_players", "players"
  add_foreign_key "game_sessions", "games"
  add_foreign_key "players", "game_sessions"
  add_foreign_key "players", "users"
end
