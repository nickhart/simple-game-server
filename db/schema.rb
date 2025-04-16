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

ActiveRecord::Schema[7.1].define(version: 2025_04_16_011650) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "game_sessions", force: :cascade do |t|
    t.bigint "game_id"
    t.bigint "creator_id"
    t.integer "min_players"
    t.integer "max_players"
    t.string "name", default: ""
    t.string "status", default: "waiting"
    t.jsonb "state", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_game_sessions_on_creator_id"
    t.index ["game_id"], name: "index_game_sessions_on_game_id"
  end

  create_table "game_sessions_players", id: false, force: :cascade do |t|
    t.bigint "game_session_id", null: false
    t.bigint "player_id", null: false
    t.index ["game_session_id", "player_id"], name: "index_game_sessions_players_on_game_session_id_and_player_id", unique: true
  end

  create_table "games", force: :cascade do |t|
    t.string "name", null: false
    t.text "state_json_schema"
    t.integer "min_players", default: 2
    t.integer "max_players", default: 10
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_games_on_name", unique: true
  end

  create_table "players", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_players_on_user_id"
  end

  create_table "tokens", force: :cascade do |t|
    t.string "jti", null: false
    t.string "token_type", null: false
    t.datetime "expires_at", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_tokens_on_jti", unique: true
    t.index ["user_id"], name: "index_tokens_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.string "role", default: "player", null: false
    t.jsonb "tokens", default: {}, null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "token_version", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "game_sessions", "games"
  add_foreign_key "game_sessions", "players", column: "creator_id"
  add_foreign_key "players", "users"
  add_foreign_key "tokens", "users"
end
