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

ActiveRecord::Schema.define(version: 20150918004400) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "lessons", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "order_id"
    t.datetime "purchased_at"
    t.datetime "expires_at"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "lessons", ["order_id"], name: "index_lessons_on_order_id", using: :btree
  add_index "lessons", ["user_id"], name: "index_lessons_on_user_id", using: :btree

  create_table "orders", force: :cascade do |t|
    t.integer  "user_id"
    t.decimal  "total",             precision: 12, scale: 3
    t.integer  "quantity"
    t.json     "merchant_response"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.integer  "legacy_id"
  end

  create_table "products", force: :cascade do |t|
    t.string   "name"
    t.integer  "quantity"
    t.decimal  "price",              precision: 6, scale: 3
    t.boolean  "active"
    t.text     "paypal_button_code"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.string   "offer_code"
  end

  create_table "students", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.string   "first_name", null: false
    t.string   "last_name"
    t.string   "avatar"
    t.date     "dob"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "legacy_id"
  end

  add_index "students", ["user_id"], name: "index_students_on_user_id", using: :btree

  create_table "testimonials", force: :cascade do |t|
    t.string   "name",       null: false
    t.text     "body",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "time_slots", force: :cascade do |t|
    t.datetime "start_at",      null: false
    t.integer  "duration",      null: false
    t.integer  "instructor_id", null: false
    t.integer  "student_id"
    t.integer  "lesson_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "legacy_id"
  end

  add_index "time_slots", ["instructor_id"], name: "index_time_slots_on_instructor_id", using: :btree
  add_index "time_slots", ["lesson_id"], name: "index_time_slots_on_lesson_id", using: :btree
  add_index "time_slots", ["student_id"], name: "index_time_slots_on_student_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "",         null: false
    t.string   "encrypted_password",     default: "",         null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,          null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "phone"
    t.string   "role",                   default: "customer"
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.string   "provider"
    t.string   "uid"
    t.text     "profile"
    t.string   "avatar"
    t.integer  "legacy_id"
    t.integer  "lessons_count"
    t.boolean  "is_instructor",          default: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["provider"], name: "index_users_on_provider", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["uid"], name: "index_users_on_uid", using: :btree

end
