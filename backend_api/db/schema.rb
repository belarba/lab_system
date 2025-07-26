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

ActiveRecord::Schema[8.0].define(version: 2025_07_26_123111) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "exam_requests", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "doctor_id", null: false
    t.bigint "exam_type_id", null: false
    t.datetime "scheduled_date"
    t.string "status"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["doctor_id"], name: "index_exam_requests_on_doctor_id"
    t.index ["exam_type_id"], name: "index_exam_requests_on_exam_type_id"
    t.index ["patient_id", "doctor_id"], name: "index_exam_requests_on_patient_id_and_doctor_id"
    t.index ["patient_id"], name: "index_exam_requests_on_patient_id"
    t.index ["scheduled_date"], name: "index_exam_requests_on_scheduled_date"
    t.index ["status"], name: "index_exam_requests_on_status"
  end

  create_table "exam_results", force: :cascade do |t|
    t.bigint "exam_request_id", null: false
    t.decimal "value"
    t.string "unit"
    t.bigint "lab_technician_id", null: false
    t.datetime "performed_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "lab_file_upload_id"
    t.index ["exam_request_id"], name: "index_exam_results_on_exam_request_id"
    t.index ["lab_file_upload_id"], name: "index_exam_results_on_lab_file_upload_id"
    t.index ["lab_technician_id"], name: "index_exam_results_on_lab_technician_id"
    t.index ["performed_at"], name: "index_exam_results_on_performed_at"
  end

  create_table "exam_types", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.text "reference_range"
    t.string "unit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "lab_file_uploads", force: :cascade do |t|
    t.string "filename", null: false
    t.integer "file_size"
    t.string "status", default: "pending"
    t.datetime "processed_at"
    t.bigint "uploaded_by_id", null: false
    t.integer "total_records", default: 0
    t.integer "processed_records", default: 0
    t.integer "failed_records", default: 0
    t.text "error_details"
    t.text "processing_summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "original_filename"
    t.string "file_hash"
    t.datetime "processing_started_at"
    t.datetime "processing_completed_at"
    t.integer "retry_count", default: 0
    t.string "file_encoding"
    t.string "detected_delimiter"
    t.text "detected_headers"
    t.index ["created_at", "status"], name: "index_lab_file_uploads_on_created_at_and_status"
    t.index ["file_hash"], name: "index_lab_file_uploads_on_file_hash"
    t.index ["processed_at"], name: "index_lab_file_uploads_on_processed_at"
    t.index ["processing_started_at"], name: "index_lab_file_uploads_on_processing_started_at"
    t.index ["retry_count"], name: "index_lab_file_uploads_on_retry_count"
    t.index ["status"], name: "index_lab_file_uploads_on_status"
    t.index ["uploaded_by_id", "status"], name: "index_lab_file_uploads_on_uploaded_by_id_and_status"
    t.index ["uploaded_by_id"], name: "index_lab_file_uploads_on_uploaded_by_id"
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_refresh_tokens_on_expires_at"
    t.index ["token"], name: "index_refresh_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_roles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "exam_requests", "exam_types"
  add_foreign_key "exam_requests", "users", column: "doctor_id"
  add_foreign_key "exam_requests", "users", column: "patient_id"
  add_foreign_key "exam_results", "exam_requests"
  add_foreign_key "exam_results", "lab_file_uploads"
  add_foreign_key "exam_results", "users", column: "lab_technician_id"
  add_foreign_key "lab_file_uploads", "users", column: "uploaded_by_id"
  add_foreign_key "refresh_tokens", "users"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
end
