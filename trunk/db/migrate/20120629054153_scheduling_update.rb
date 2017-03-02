class SchedulingUpdate < ActiveRecord::Migration
	def up
		#
		# Shouldthis schedule run at this exact time across all time zones?
		#
		add_column		:schedules, :sync_all_zones,	:boolean,	:allow_null => false,	:default => false
		add_column		:schedules, :play_time,			:integer,	:allow_null => false
		add_column		:schedules, :end_job_id,		:integer
		
		add_column		:displays, :last_seen, 			:datetime
		add_column		:displays, :api, 				:integer,	:allow_null => false,	:default => 1
		remove_column	:displays, :force_update
		
		remove_column	:playlists, :published_new
		
		
		#
		# These are the schedule relative to the displays local time
		#
		create_table :display_schedules do |t|
			t.references	:display,	:allow_null => false
			t.references	:schedule,	:allow_null => false
			
			t.integer		:start_job_id
			t.integer		:end_job_id
			
			t.datetime		:do_start,	:allow_null => false
			t.datetime		:do_end,	:allow_null => false
		end
		
		#
		# This is how we will minimise updates
		# Only update displays when:
		# => the cache is added to this list
		# => the cache is removed before schedule end
		#
		# No need to update when:
		# => a cache is removed due to schedule end
		#
		create_table :display_caches do |t|
			t.references	:display,	:allow_null => false
			t.references	:schedule,	:allow_null => false
		end
		
		
		create_table :scheduled_jobs do |t|
			t.references	:display_group,		:allow_null => false
			t.boolean		:start_job,			:allow_null => false,	:default => true
			t.integer		:job_id,			:allow_null => false
			t.integer		:schedule_count,	:allow_null => false,	:default => 0
			t.datetime		:schedule_time,		:allow_null => false
		end
		
		#
		# TODO:: We need to transfer existing schedules to the new format
		#
	end

	def down
	end
end
