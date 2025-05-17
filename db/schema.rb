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

ActiveRecord::Schema[7.1].define(version: 2024_06_07_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "cron"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "expenses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "user_category_id"
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.text "description"
    t.date "date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_expenses_on_date"
    t.index ["user_category_id"], name: "index_expenses_on_user_category_id"
    t.index ["user_id"], name: "index_expenses_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "subscription_id"
    t.boolean "used", default: false
    t.boolean "accepted"
    t.decimal "amount"
    t.string "subscription_type"
    t.jsonb "parameters"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subscription_id"], name: "index_payments_on_subscription_id"
  end

  create_table "settings", force: :cascade do |t|
    t.bigint "user_id"
    t.string "currency"
    t.string "language"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true
    t.integer "period_start_day", default: 1, null: false
    t.index ["user_id"], name: "index_settings_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "user_id"
    t.datetime "payed_for"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "user_categories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "emoji", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_user_categories_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_user_categories_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.bigint "chat_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "expenses", "user_categories"
  add_foreign_key "expenses", "users"
  add_foreign_key "payments", "subscriptions"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "user_categories", "users"
end
