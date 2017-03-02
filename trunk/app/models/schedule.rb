class Schedule < ActiveRecord::Base
	belongs_to	:playlist
	belongs_to	:display_group
	has_many	:displays, :through => :display_group
	
	
	belongs_to :end_job,	:class_name => "ScheduledJob"
    
    
	before_destroy	:remove_end_job
	has_many		:display_caches,	:inverse_of => :schedules	# IMPORTANT this be here and dependent set!!! As before_destroy needs to be called first
	has_many		:display_schedules,	:inverse_of => :schedule,	:dependent => :destroy	# IMPORTANT this be here so we can clean up the jobs
	
	validate 		:schedule_not_expired
	
	
	
	#
	# TODO:: Process:
	#	* Create the schedule (is always created assuming start < end)
	#	* Background job creates the display_schedules (They are created, rolled forward etc)
	#	* If there are display_schedules then the display caches are updated
	#	** If there are no display_schedules then the schedule is destroyed (no cache invalidation)
	#
	
    
    self.include_root_in_json = false
    
	
	#
	# This is a ruby version of the JSON calendar event that is required
	#
	class Event
		attr_accessor :id, :title, :color, :textColor
		attr_accessor :allDay, :start, :end
	end
	
	REPEAT_TYPES = [
		["Never", lambda {|x| 0}],
		["Every Day", lambda {|x| x.days}],
		["Every Week", lambda {|x| x.weeks}],
		["Every 2 Weeks", lambda {|x| x.fortnights}],
		["Every Month", lambda {|x| x.months}],
		["Every Year", lambda {|x| x.years}]
	]
	

	#
	# This is used to take into account daylight savings time changes
	#	which effect playtime as time is either added or subtracted (we have to re-adjust)
	#
	def self.adjust_offsets(offset, time)
		if offset != time.utc_offset
			time += offset - time.utc_offset
		end

		return time
	end
	
	
	def self.get_events(group, startLocal, endLocal, tzone)
		calstart = startLocal.new_zone('Etc/GMT+12')			# This is UTC -12 and there is no daylight saving
		calend = endLocal.new_zone('Etc/GMT+12')
		
		
		schedules = Schedule.where('display_group_id = ? AND repeat_period = 0 AND (((do_start < ? AND do_end > ?) AND sync_all_zones = ?) OR ((do_start < ? AND do_end > ?) AND sync_all_zones = ?))', group, calend, calstart, false, endLocal, startLocal, true)
		repeats = Schedule.where('display_group_id = ? AND repeat_period > 0 AND ((end_repeat > ? AND sync_all_zones = ?) OR (end_repeat > ? AND sync_all_zones = ?) OR end_repeat IS NULL)', group, calstart, false, startLocal, true)	# Calstart so we can get the tail end of a repeat
		events = []
		
		#
		# Generate all the events for repeated schedules
		#
		repeats.find_each do |schedule|
			do_start = schedule.sync_all_zones ? schedule.do_start.in_time_zone(tzone) : schedule.do_start.new_zone(tzone)
			do_end = schedule.sync_all_zones ? schedule.do_end.in_time_zone(tzone) : schedule.do_end.new_zone(tzone)
			end_repeat = schedule.sync_all_zones ? schedule.end_repeat.in_time_zone(tzone) : schedule.end_repeat.new_zone(tzone) unless schedule.end_repeat.nil?
			
			offset = (startLocal - do_start)
			play_time = schedule.play_time
			repeat_offset = REPEAT_TYPES[schedule.repeat_period][1]	# Get lambda function for the repeat type
			
			
			#
			# move schedule into range of the current calendar
			#	Account for daylight savings
			#
			if offset.to_i > play_time	# ie if offset not close to the start of an event
				do_start += repeat_offset.call((offset / repeat_offset.call(1)).ceil)
				do_end = do_start + play_time	# end time here as we have just adjusted
				do_end = adjust_offsets(do_start.utc_offset, do_end)
			end
			
			#
			# Create any events and move the repeat window
			#
			while do_start < endLocal && do_end > startLocal
				if end_repeat != nil && do_end > end_repeat	# Check we are not past the end repeat date
					break
				end
					
				event = Event.new
				event.id = schedule.id
				event.start = do_start.iso8601
				event.end = do_end.iso8601
				event.title = schedule.playlist.name
				event.allDay = schedule.all_day
				event.color = schedule.emergency ? "red" : schedule.exclusive ? "orange" : "blue"
				event.textColor = schedule.emergency ? "yellow" : schedule.exclusive ? "black" : "white"
				
				events << event
				
				do_start += repeat_offset.call(1)	# Move the repeat window
				do_end = do_start + play_time
				do_end = adjust_offsets(do_start.utc_offset, do_end)
			end
		end
	
		#
		# Add the remaining events
		#
		schedules.find_each do |schedule|
			event = Event.new
			event.id = schedule.id
			event.start = schedule.sync_all_zones ? schedule.do_start.in_time_zone(tzone).iso8601 : schedule.do_start.new_zone(tzone).iso8601
			event.end = schedule.sync_all_zones ? schedule.do_end.in_time_zone(tzone).iso8601 : schedule.do_end.new_zone(tzone).iso8601
			event.title = schedule.playlist.name
			event.allDay = schedule.all_day
			event.color = schedule.emergency ? "red" : schedule.exclusive ? "orange" : "blue"
			event.textColor = schedule.emergency ? "yellow" : schedule.exclusive ? "black" : "white"
			
			events << event
		end
		
		return events
	end
	
	
	
	protected


	
    def schedule_not_expired
    	#
        # If the schedule ends in the past we need to roll it forward
        #   If it is not a repeating schedule we ensure the creation/save fails (for the user to remove)
        #   the past is defined as 1min from now (slight time buffer)
        #
		if self.do_start > self.do_end
			errors.add(:do_end, 'Unable to add a schedule that ends before it starts')
			return
		end
		
		times_changed = false
		
		if self.do_end_changed? || self.do_start_changed?
			times_changed = true
			self.play_time = (self.do_end - self.do_start).to_i
		end
		
        if self.do_end < Time.now
        	if repeat_period <= 0
        		errors.add(:do_end, 'Unable to add a schedule that ends in the past')
        	else
        		next_window
        	end
        end
        
        if errors.empty?
        	schedule_jobs(times_changed)
        end
    end
    
    
    #
	# Move window for repeating events
	# => Similar algorithm for get_events
	#
	def next_window
		
		repeat_offset = Schedule::REPEAT_TYPES[repeat_period][1]	# Get lambda function for the repeat type
		
		self.do_start += repeat_offset.call(1)		# Move the repeat window
		offset = (Time.now - self.do_start)
		
		#
		# Check we are as close to the current time as possible
		#	Avoids repeated events being lost in the past
		#
		if offset.to_i > play_time	# ie if offset not close to the start of an event
			self.do_start += repeat_offset.call((offset / repeat_offset.call(1)).ceil)
		end
		
		#
		# No need to adjust for daylight savings here as we are using UTC
		#	Daylight savings is per-display
		#
		self.do_end = self.do_start + self.play_time
		
		#
		# Make sure we haven't past our deadline
		#
		if !self.end_repeat.nil? && self.do_end > self.end_repeat
			errors.add(:end_repeat, 'Schedule has past its end date')
		end
	end
	
	
	def remove_end_job
		endjob = ScheduledJob.where(:id => self.end_job_id).first
		
		if endjob.present?
			endjob.with_lock do
				if endjob.schedule_count <= 1
					endjob.destroy
				else
					endjob.decrement!(:schedule_count)
				end
			end
		end
		
		self.end_job = nil unless self.destroyed?
	end
    
    
	def schedule_jobs(user_changed)
		#
		# Validation has confirmed the schedule ends in the future:
		#   * Remove any existing jobs
		#   * Create a job to run when the schedule ends
		#
		if self.do_end_changed?
			remove_end_job
			
			self.end_job = ScheduledJob.where(:start_job => false, :schedule_time => self.do_end).first_or_initialize
			self.end_job.increment(:schedule_count)
			self.end_job.save!
		end
		
		
		#
		# Save the schedule with the jobs added
		#
		self.save(:validate => false)
		
		
		#
		# Check if it was a new record we may need to do a cache update
		#
		if user_changed
			Delayed::Job.enqueue ScheduleUpdateJob.new(self.id), :queue => 'schedule', :run_at => 2.seconds.from_now unless self.id.nil?
		end
	end
end
