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
		# Transfer existing schedules to the new format
		#
		Display.reset_column_information
		ScheduledJob.reset_column_information
		DisplayCache.reset_column_information
		DisplaySchedule.reset_column_information
		Schedule.reset_column_information
		
		#
		# fixes timezone changes - Update this assumption per-client
		#
		Schedule.find_each do |schedule|
			schedule.do_start_will_change!
			schedule.do_end_will_change!
			schedule.do_start = schedule.do_start.in_time_zone('Sydney').new_zone('Etc/GMT+12')
			schedule.do_end = schedule.do_end.in_time_zone('Sydney').new_zone('Etc/GMT+12')
			schedule.play_time = (schedule.do_end - schedule.do_start).to_i
			schedule.save
		end
	end

	def down
	end
end
