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

ActiveRecord::Schema.define(version: 20160218190619) do

  create_table "jobs", force: true do |t|
    t.string   "type"
    t.integer  "workflow_id"
    t.string   "status"
    t.text     "job_cache"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "jobs", ["workflow_id"], name: "index_jobs_on_workflow_id"

  create_table "uploads", force: true do |t|
    t.string   "type"
    t.integer  "workflow_id"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "uploads", ["workflow_id"], name: "index_uploads_on_workflow_id"

  create_table "workflows", force: true do |t|
    t.string   "type"
    t.integer  "parent_id"
    t.string   "name"
    t.string   "staged_dir"
    t.text     "data"
    t.integer  "version"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "workflows", ["parent_id"], name: "index_workflows_on_parent_id"

end
