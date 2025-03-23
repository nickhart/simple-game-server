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

ActiveRecord::Schema[8.0].define(version: 2025_03_23_193724) do
  create_table "game_players", force: :cascade do |t|
    t.integer "game_session_id", null: false
    t.integer "player_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_session_id"], name: "index_game_players_on_game_session_id"
    t.index ["player_id"], name: "index_game_players_on_player_id"
  end

  create_table "game_sessions", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.integer "min_players", default: 2, null: false
    t.integer "max_players", default: 4, null: false
    t.integer "current_player_index"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "players", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "game_players", "game_sessions"
  add_foreign_key "game_players", "players"
end
