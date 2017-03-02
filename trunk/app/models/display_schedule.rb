class DisplaySchedule < ActiveRecord::Base
    belongs_to	:schedule,	:inverse_of => :display_schedules
    belongs_to	:display,	:inverse_of => :display_schedules
    
    before_destroy	:remove_jobs
    before_destroy	:invalidate_cache			# NOTE:: This destroys the display_caches below
    has_many	:display_caches,	:through => :schedule, :conditions => proc { ["display_caches.display_id = ?", display_id] }
    
	belongs_to :start_job,	:class_name => "ScheduledJob"
	belongs_to :end_job,	:class_name => "ScheduledJob"
    
	validate :schedule_not_expired
	
	
	
	
	protected
	
	
	def schedule_not_expired
    	#
        # If the schedule ends in the past we need to roll it forward
        #   If it is not a repeating schedule we ensure the creation/save fails (for the user to remove)
        #   the past is defined as 1min from now (slight time buffer)
        #
        if self.do_end < Time.now
        	if self.schedule.repeat_period <= 0
        		errors.add(:do_end, 'Unable to add a schedule that ends in the past')
			else
        		next_window
        	end
        end
        
        if errors.empty?
        	schedule_jobs
        end
    end
	
	def schedule_jobs
		
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
		# if the schedule has already started or starts in the future
		#   * Remove any existing jobs
		#   * Create a job that will update the effected displays
		#
		if self.do_start_changed?
			remove_start_job
			
			if self.do_start > Time.now
				self.start_job = ScheduledJob.where(:start_job => true, :schedule_time => self.do_start).first_or_initialize
				self.start_job.increment(:schedule_count)
				self.start_job.save!
			else
				self.start_job = nil
			end
		end
		
		
		#
		# Check if it was a new record we may need to do a cache update
		#
		if self.do_start_changed? || self.do_end_changed?
			if self.display_caches.exists?
				invalidate_cache
			else
				do_cache_update
			end
		end
		
		
		#
		# Save the schedule with the jobs added
		#
		self.save(:validate => false)
	end



	def timezone
		return self.schedule.sync_all_zones ? 'Etc/GMT+12' : self.display.timezone
	end



	#
	# Move window for repeating events
	#
	def next_window
	
		repeat_offset = Schedule::REPEAT_TYPES[self.schedule.repeat_period][1]	# Get lambda function for the repeat type
	
		thestart = self.do_start.in_time_zone(timezone) + repeat_offset.call(1)		# Move the repeat window
		offset = (Time.now - thestart)
	
		#
		# Check we are as close to the current time as possible
		#	Avoids repeated events being lost in the past
		#
		if offset.to_i > self.schedule.play_time	# ie if offset not close to the start of an event
			thestart += repeat_offset.call((offset / repeat_offset.call(1)).ceil)
		end
	
		#
		# adjust the end time and check for daylight savings
		#
		theend = thestart + self.schedule.play_time
		self.do_end = Schedule.adjust_offsets(thestart.utc_offset, theend)	# adjust if we went over a daylight savings time
		self.do_start = thestart
		
		#
		# Make sure we haven't past our deadline
		#
		if !self.schedule.end_repeat.nil?
			end_repeat = self.schedule.sync_all_zones ? self.schedule.end_repeat : self.schedule.end_repeat.new_zone(timezone)
			if self.do_end > end_repeat
				errors.add(:end_repeat, 'Schedule has past its end date')
			end
		end
	end
	
	
    
	
	#
	# Job removal code
	#
	def remove_jobs
		remove_start_job
		remove_end_job
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
	
	def remove_start_job
		startjob = ScheduledJob.where(:id => self.start_job_id).first
		
		if startjob.present?
			startjob.with_lock do
				if startjob.schedule_count <= 1
					startjob.destroy
				else
					startjob.decrement!(:schedule_count)
				end
			end
		end
		
		self.start_job = nil unless self.destroyed?
	end
	
	
	#
	# This only updates the cache for the individual display
	#
	def invalidate_cache
		if self.display_caches.exists?
			ids = self.display_caches.pluck('display_caches.id')
			DisplayCache.where('id IN (?)', ids).delete_all
			do_cache_update(true)
		end
	end
	
	def do_cache_update(force = false)
		Delayed::Job.enqueue ScheduleCacheUpdate.new(self.display_id, force), :queue => 'schedule'
	end

end
