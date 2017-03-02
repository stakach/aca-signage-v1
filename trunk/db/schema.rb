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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120629054153) do

  create_table "accepts_files", :force => true do |t|
    t.string  "ext"
    t.string  "mime"
    t.boolean "enabled"
  end

  create_table "authentications", :force => true do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "uid"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "captions", :force => true do |t|
    t.string  "title"
    t.string  "caption"
    t.integer "timeout",     :default => 5
    t.integer "font_size",   :default => 40
    t.string  "font_family"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "queue"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "display_caches", :force => true do |t|
    t.integer "display_id"
    t.integer "schedule_id"
  end

  create_table "display_groupings", :force => true do |t|
    t.integer "display_group_id"
    t.integer "display_id"
  end

  create_table "display_groups", :force => true do |t|
    t.integer  "playlist_id"
    t.integer  "group_id"
    t.string   "name"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_updated", :default => '2000-01-01 00:00:00'
  end

  create_table "display_schedules", :force => true do |t|
    t.integer  "display_id"
    t.integer  "schedule_id"
    t.integer  "start_job_id"
    t.integer  "end_job_id"
    t.datetime "do_start"
    t.datetime "do_end"
  end

  create_table "displays", :force => true do |t|
    t.string   "name"
    t.string   "building"
    t.string   "location"
    t.text     "comment"
    t.text     "link"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_updated",   :default => '2011-08-29 04:09:41'
    t.datetime "last_emailed"
    t.datetime "window_start"
    t.datetime "window_end"
    t.boolean  "notify_offline", :default => false,                 :null => false
    t.string   "timezone"
    t.string   "permalink"
    t.boolean  "physical",       :default => true,                  :null => false
    t.boolean  "forward_back",   :default => false,                 :null => false
    t.boolean  "geolocate",      :default => false,                 :null => false
    t.integer  "max_space",      :default => 0,                     :null => false
    t.integer  "wdays",          :default => 127,                   :null => false
    t.datetime "last_seen"
    t.integer  "api",            :default => 1
  end

  create_table "file_conversions", :force => true do |t|
    t.integer  "accepts_file_id"
    t.string   "applies_to"
    t.text     "command"
    t.string   "description"
    t.boolean  "enabled",         :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ordinal"
    t.integer  "target_id"
    t.integer  "width"
    t.integer  "height"
  end

  create_table "formats", :force => true do |t|
    t.integer "media_id"
    t.integer "accepts_file_id"
    t.integer "target_id"
    t.text    "file_path"
    t.string  "workflow_state"
  end

  create_table "group_displays", :force => true do |t|
    t.integer "group_id"
    t.integer "display_id"
  end

  create_table "group_hierarchies", :id => false, :force => true do |t|
    t.integer "ancestor_id",   :null => false
    t.integer "descendant_id", :null => false
    t.integer "generations",   :null => false
  end

  add_index "group_hierarchies", ["ancestor_id", "descendant_id"], :name => "index_group_hierarchies_on_ancestor_id_and_descendant_id", :unique => true
  add_index "group_hierarchies", ["descendant_id"], :name => "index_group_hierarchies_on_descendant_id"

  create_table "group_medias", :force => true do |t|
    t.integer "group_id"
    t.integer "media_id"
  end

  create_table "groups", :force => true do |t|
    t.integer  "parent_id"
    t.string   "identifier"
    t.string   "description"
    t.string   "timezone"
    t.string   "domain"
    t.text     "notes"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.boolean  "publisher",   :default => true
  end

  create_table "histories", :force => true do |t|
    t.integer  "user_id"
    t.string   "table_name"
    t.integer  "table_id"
    t.boolean  "deleted",    :default => false
    t.text     "objectxml"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "identities", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "password_digest"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "invites", :force => true do |t|
    t.integer  "group_id"
    t.integer  "permissions"
    t.string   "email"
    t.string   "secret"
    t.datetime "expires"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "medias", :force => true do |t|
    t.string   "name"
    t.string   "comment"
    t.text     "file_path"
    t.string   "workflow_state"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "media_type",                                     :null => false
    t.integer  "width"
    t.integer  "height"
    t.integer  "runtime"
    t.integer  "plugin_id"
    t.string   "background",     :limit => 6, :default => "000"
    t.integer  "caption_id"
    t.integer  "user_id"
    t.integer  "interactive"
  end

  create_table "playlist_medias", :force => true do |t|
    t.integer  "group_media_id"
    t.integer  "playlist_id"
    t.integer  "run_time"
    t.integer  "start_time"
    t.integer  "ordinal"
    t.boolean  "deleted",               :default => false
    t.boolean  "published",             :default => false
    t.integer  "pub_run_time"
    t.integer  "pub_start_time"
    t.integer  "pub_ordinal"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "transition_effect",     :default => 0
    t.integer  "pub_transition_effect", :default => 0
  end

  create_table "playlists", :force => true do |t|
    t.integer  "group_id"
    t.string   "name"
    t.text     "comment"
    t.integer  "default_timeout",    :default => 30
    t.datetime "published_at",       :default => '2011-08-29 04:09:39'
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "display_group_id"
    t.boolean  "random",             :default => false
    t.integer  "preload",            :default => 0
    t.integer  "default_transition", :default => 0
  end

  create_table "plugins", :force => true do |t|
    t.integer "group_id"
    t.string  "name"
    t.text    "file_path"
    t.text    "help"
    t.text    "validation"
    t.boolean "can_play_to_end", :default => false
    t.boolean "requires_data",   :default => true
  end

  create_table "resolute_resumables", :force => true do |t|
    t.string   "user_id"
    t.text     "custom_params"
    t.string   "file_name"
    t.integer  "file_size"
    t.datetime "file_modified"
    t.text     "file_location"
  end

  create_table "scheduled_jobs", :force => true do |t|
    t.integer  "display_group_id"
    t.boolean  "start_job",        :default => true
    t.integer  "job_id"
    t.integer  "schedule_count",   :default => 0
    t.datetime "schedule_time"
  end

  create_table "schedules", :force => true do |t|
    t.integer  "playlist_id"
    t.integer  "display_group_id"
    t.text     "notes"
    t.boolean  "exclusive",        :default => false
    t.boolean  "emergency",        :default => false
    t.boolean  "all_day",          :default => false
    t.datetime "do_start",         :default => '2011-08-29 04:09:41'
    t.datetime "do_end",           :default => '2011-08-29 04:09:41'
    t.integer  "repeat_period",    :default => 0
    t.datetime "end_repeat"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "sync_all_zones",   :default => false
    t.integer  "play_time"
    t.integer  "end_job_id"
  end

  create_table "stats", :force => true do |t|
    t.integer "display_id"
    t.integer "media_id"
    t.integer "displayed",     :default => 0
    t.integer "error_count",   :default => 0
    t.integer "interacted",    :default => 0
    t.integer "displayed_for", :default => 0
    t.string  "last_error"
  end

  create_table "targets", :force => true do |t|
    t.string "identifier"
    t.text   "notes"
  end

  create_table "thumbnails", :force => true do |t|
    t.integer "media_id"
    t.text    "file_path"
    t.integer "at_time",   :default => 0
  end

  create_table "user_groups", :force => true do |t|
    t.integer  "group_id"
    t.integer  "user_id"
    t.integer  "permissions", :default => 0
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "identifier"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email"
    t.text     "notes"
    t.string   "timezone"
    t.boolean  "system_admin", :default => false
    t.string   "firstname"
    t.string   "lastname"
    t.integer  "login_count",  :default => 0
  end

end
