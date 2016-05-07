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

ActiveRecord::Schema.define(version: 20160507173533) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string   "slug",                      null: false
    t.integer  "sluggable_id",              null: false
    t.string   "sluggable_type", limit: 50
    t.string   "scope"
    t.datetime "created_at"
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true, using: :btree
  add_index "friendly_id_slugs", ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", using: :btree
  add_index "friendly_id_slugs", ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
  add_index "friendly_id_slugs", ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree

  create_table "lesson_transfers", force: :cascade do |t|
    t.integer  "quantity",     null: false
    t.integer  "user_id"
    t.integer  "recipient_id", null: false
    t.text     "notes"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "lesson_transfers", ["user_id"], name: "index_lesson_transfers_on_user_id", using: :btree

  create_table "lessons", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "order_id"
    t.datetime "purchased_at"
    t.datetime "expires_at"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.integer  "lesson_transfer_id"
  end

  add_index "lessons", ["order_id"], name: "index_lessons_on_order_id", using: :btree
  add_index "lessons", ["user_id"], name: "index_lessons_on_user_id", using: :btree

  create_table "locations", force: :cascade do |t|
    t.string   "name"
    t.string   "street_address"
    t.string   "city"
    t.string   "state"
    t.string   "zip_code"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.string   "slug"
  end

  add_index "locations", ["slug"], name: "index_locations_on_slug", unique: true, using: :btree

  create_table "orders", force: :cascade do |t|
    t.integer  "user_id"
    t.decimal  "total",             precision: 12, scale: 3
    t.integer  "quantity"
    t.json     "merchant_response"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.integer  "legacy_id"
    t.string   "remote_order_id"
  end

  add_index "orders", ["remote_order_id", "user_id"], name: "index_orders_on_remote_order_id_and_user_id", unique: true, using: :btree

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
    t.integer  "location_id"
  end

  add_index "time_slots", ["instructor_id"], name: "index_time_slots_on_instructor_id", using: :btree
  add_index "time_slots", ["lesson_id"], name: "index_time_slots_on_lesson_id", using: :btree
  add_index "time_slots", ["location_id"], name: "index_time_slots_on_location_id", using: :btree
  add_index "time_slots", ["student_id"], name: "index_time_slots_on_student_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                         default: "",         null: false
    t.string   "encrypted_password",            default: "",         null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                 default: 0,          null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "phone"
    t.string   "role",                          default: "customer"
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.string   "provider"
    t.string   "uid"
    t.text     "profile"
    t.string   "avatar"
    t.integer  "legacy_id"
    t.integer  "lessons_count"
    t.boolean  "is_instructor",                 default: false
    t.integer  "referer_id"
    t.integer  "referral_free_lesson_order_id"
    t.string   "stripe_customer_id"
    t.boolean  "i_agree",                       default: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["provider"], name: "index_users_on_provider", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["uid"], name: "index_users_on_uid", using: :btree

  add_foreign_key "lesson_transfers", "users"
end
