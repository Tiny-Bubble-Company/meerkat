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

ActiveRecord::Schema[8.1].define(version: 2026_06_21_150000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
  end

  create_table "api_keys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.datetime "last_used_at"
    t.string "name", default: "Default", null: false
    t.datetime "revoked_at"
    t.string "token_digest", null: false
    t.string "token_prefix", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "revoked_at"], name: "index_api_keys_on_customer_id_and_revoked_at"
    t.index ["customer_id"], name: "index_api_keys_on_customer_id"
    t.index ["token_digest"], name: "index_api_keys_on_token_digest", unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.string "company"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.text "llm_api_key_ciphertext"
    t.string "llm_model"
    t.string "llm_provider"
    t.string "name"
    t.datetime "onboarding_completed_at"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_customers_on_email", unique: true
  end

  create_table "task_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.jsonb "payload", default: {}, null: false
    t.bigint "task_id", null: false
    t.bigint "task_run_id"
    t.datetime "updated_at", null: false
    t.datetime "webhook_delivered_at"
    t.integer "webhook_response_code"
    t.string "webhook_url"
    t.index ["event_type"], name: "index_task_events_on_event_type"
    t.index ["task_id", "created_at"], name: "index_task_events_on_task_id_and_created_at"
    t.index ["task_id"], name: "index_task_events_on_task_id"
    t.index ["task_run_id"], name: "index_task_events_on_task_run_id"
  end

  create_table "task_runs", force: :cascade do |t|
    t.boolean "change_detected", default: false, null: false
    t.datetime "created_at", null: false
    t.text "error"
    t.datetime "finished_at"
    t.text "output"
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.jsonb "structured_output", default: {}, null: false
    t.bigint "task_id", null: false
    t.datetime "updated_at", null: false
    t.jsonb "usage", default: {}, null: false
    t.index ["status"], name: "index_task_runs_on_status"
    t.index ["task_id", "created_at"], name: "index_task_runs_on_task_id_and_created_at"
    t.index ["task_id"], name: "index_task_runs_on_task_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.integer "consecutive_failures", default: 0, null: false
    t.datetime "created_at", null: false
    t.bigint "customer_id"
    t.text "description", null: false
    t.string "frequency"
    t.integer "frequency_seconds"
    t.jsonb "input_params", default: {}, null: false
    t.jsonb "last_known_state", default: {}, null: false
    t.datetime "last_run_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "next_run_at"
    t.string "output_format"
    t.string "output_webhook"
    t.integer "run_count", default: 0, null: false
    t.string "status", default: "active", null: false
    t.string "task_type", default: "recurring", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "status"], name: "index_tasks_on_customer_id_and_status"
    t.index ["customer_id"], name: "index_tasks_on_customer_id"
    t.index ["next_run_at"], name: "index_tasks_on_next_run_at"
    t.index ["status", "next_run_at"], name: "index_tasks_on_status_and_next_run_at"
    t.index ["status"], name: "index_tasks_on_status"
    t.index ["task_type", "status", "next_run_at"], name: "index_tasks_on_type_status_and_next_run_at"
    t.index ["task_type", "status"], name: "index_tasks_on_task_type_and_status"
    t.index ["task_type"], name: "index_tasks_on_task_type"
  end

  add_foreign_key "api_keys", "customers"
  add_foreign_key "task_events", "task_runs"
  add_foreign_key "task_events", "tasks"
  add_foreign_key "task_runs", "tasks"
  add_foreign_key "tasks", "customers"
end
