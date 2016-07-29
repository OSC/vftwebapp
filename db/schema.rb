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

ActiveRecord::Schema.define(version: 20160728141500) do

  create_table "meshes", force: :cascade do |t|
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "upload_file_name"
    t.string   "upload_content_type"
    t.integer  "upload_file_size"
    t.datetime "upload_updated_at"
  end

  create_table "session_jobs", force: :cascade do |t|
    t.integer  "session_id"
    t.string   "status"
    t.text     "job_cache"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "session_jobs", ["session_id"], name: "index_session_jobs_on_session_id"

  create_table "sessions", force: :cascade do |t|
    t.integer  "mesh_id"
    t.integer  "state"
    t.text     "vftsolid_data"
    t.text     "thermal_data"
    t.text     "structural_data"
    t.text     "data"
    t.string   "staged_dir"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["mesh_id"], name: "index_sessions_on_mesh_id"

end
