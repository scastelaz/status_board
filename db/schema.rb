# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140716145131) do

  create_table "boards", force: true do |t|
    t.string  "name"
    t.integer "card_count"
    t.integer "bug_cards"
    t.float   "in_dev"
    t.float   "past_dev"
    t.string  "url_id"
  end

  create_table "cards", force: true do |t|
    t.string   "user"
    t.string   "boardable_id"
    t.string   "name"
    t.string   "list"
    t.datetime "enterDate"
    t.datetime "leaveDate"
  end

  create_table "statuses", force: true do |t|
    t.text     "body"
    t.datetime "expiration"
    t.integer  "statusable_id"
    t.string   "statusable_type"
  end

  create_table "users", force: true do |t|
    t.string "email"
    t.string "user_name"
    t.string "name"
    t.string "replicon_uri"
  end

  add_index "users", ["name"], name: "index_users_on_name", unique: true
  add_index "users", ["user_name"], name: "index_users_on_user_name", unique: true

  create_table "vacations", force: true do |t|
    t.date    "startDate"
    t.date    "endDate"
    t.integer "user_id"
  end

end
