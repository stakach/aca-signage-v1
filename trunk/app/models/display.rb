require 'uri'

class Display < ActiveRecord::Base
	has_many :display_groupings,	:dependent => :destroy
	has_many :display_groups,	:through => :display_groupings	# The group to which this display is assigned
	has_many :schedules,		:through => :display_groups
	has_many :playlists,		:through => :display_groups
	
	has_many :group_displays,	:dependent => :destroy
	has_many :groups,			:through => :group_displays
	
	has_many :display_schedules,	:inverse_of => :display,	:dependent => :destroy
	has_many :display_caches,		:inverse_of => :display,	:dependent => :delete_all
	has_many :current_schedules,	:through => :display_caches, :source => 'schedule', :class_name => "Schedule"
	has_many :current_playlists,	:through => :current_schedules, :source => 'playlist', :class_name => "Playlist"
	
	
	scope :for_group, lambda {|group| joins(:group_displays).where("group_displays.group_id = ?", group.id) }
	
	
	def self.search(group, search_terms = nil)
		result = Display.joins(:group_displays).where('group_displays.group_id = ?', group.id)
		
		if(!search_terms.nil? && search_terms != "")
			search = '%' + search_terms.chomp.gsub(' ', '%').downcase + '%'
			result = result.where('LOWER(displays.name) LIKE ? OR LOWER(displays.comment) LIKE ? OR LOWER(displays.building) LIKE ? OR LOWER(displays.location) LIKE ?', search, search, search, search)
		end
		
		return result
	end
	
	
	#
	# Update display schedules if display time zone changed!!!!!!!!!
	#
	after_update	:check_time_zone

	
	self.include_root_in_json = false
	
	
	
	#
	# Accessors for currently displaying things
	#
	def live_playlists
		Playlist.live_on(self)
	end
	
	def live_schedules
		schedules = DisplayCache.where(:display_id => self.id).pluck(:schedule_id)
		DisplaySchedule.where('display_id = ? AND schedule_id IN (?)', self.id, schedules)
	end
	
	

	#
	# Move group time into UTC
	#	Then adjust so all time values are on 2000-01-01
	#
	#	This way we have have timezone correct start and end times
	#	TODO:: Regular expression needs a check on value bounds
	#
	def start_checking=(string)
		if (string =~ /\d{1,2}:\d{1,2}/).nil?
			string = "00:00"
		end
		time = nil
		begin
			time = Time.zone.parse("2000-01-01 #{string}").new_zone(self.timezone)	# Move to correct timezone
		rescue
			time = Time.zone.parse("2000-01-01 00:00").new_zone(self.timezone)
		end
		self.window_start = time
	end
	
	def end_checking=(string)
		if (string =~ /\d{1,2}:\d{1,2}/).nil?
			string = "23:59"
		end
		time = nil
		begin
			time = Time.zone.parse("2000-01-01 #{string}").new_zone(self.timezone)	# Move to correct timezone
		rescue
			time = Time.zone.parse("2000-01-01 23:59").new_zone(self.timezone)
		end
		self.window_end = time
	end
	
	#
	# The "in_time_zone" ensures these are in the displays timezone
	#
	def start_checking
		return "00:00" if self.window_start.nil?
		time = self.window_start.in_time_zone(self.timezone)
		"#{time.hour.to_s.rjust(2,'0')}:#{time.min.to_s.rjust(2,'0')}"
	end
	
	def end_checking
		return "23:59" if self.window_end.nil?
		time = self.window_end.in_time_zone(self.timezone)
		"#{time.hour.to_s.rjust(2,'0')}:#{time.min.to_s.rjust(2,'0')}"
	end
	
	#
	# Provides a default timezone for new displays
	#
	def timezone(user = nil)
		return self[:timezone] unless self[:timezone].nil?
		return user.timezone unless user.nil? || user.timezone.nil?
		'Sydney'
	end
	
	#
	# Calculated using UTC!
	#
	def self.check_displays_online
		begin
			current_time = Time.now.utc
			time_now = Time.parse("2000-01-01 #{current_time.hour}:#{current_time.min} UTC")
			display_query = self.where(
				'notify_offline = ? AND window_start IS NOT NULL AND 
				window_end IS NOT NULL AND last_seen < ? AND last_updated IS NOT NULL AND 
				(last_emailed < last_seen OR last_emailed IS NULL) AND 
				((window_start < window_end AND window_start <= ? AND window_end >= ?) OR
				 (window_start > window_end AND (window_start <= ? OR window_end >= ?)))', 
				true, current_time - 10.minutes, time_now, time_now, time_now, time_now)
			
			if display_query.exists?
				display_query.update_all(:last_emailed => Time.now)
				
				display_query.find_each do |display|
					mail = UserMailer.send_alert(display)
					mail.deliver unless mail.to.empty?
				end
			end
		ensure
			#
			# TODO:: This task should be scheduled at the OS level
			#
			self.delay({:run_at => 5.minutes.from_now, :queue => 'display'}).check_displays_online
		end
	end

	
	#
	# These are the schedules
	#
	def update_cache(force = false)
		thetime = Time.now
		
		#
		# Find all schedules currently playing for this display
		#
		playing = self.display_schedules.where('do_start <= ? AND do_end > ?', thetime, thetime)
		thecache = playing.pluck(:schedule_id)
		
		
		last = playing.order('do_start DESC').limit(1).pluck(:do_start)
		last = last.empty? ? thetime : last[0]
		
		
		#
		# Find the first schedule occurring in the future
		#
		future = self.display_schedules.where('do_start > ?', last).order('do_start ASC').limit(1).pluck(:do_start)
		if !future.empty?
			future = future[0]
			
			#
			# Find all schedules occurring at the same time in the future
			#
			future = self.display_schedules.where('do_start = ?', future).pluck(:schedule_id)
			thecache = thecache + future
		end
		
		
		#
		# Find what changes are required
		#
		changed = false
		remove = []
		self.display_caches.pluck(:schedule_id).each do |schedule_id|
			remove << schedule_id if thecache.delete(schedule_id) == nil
		end
		
		if !remove.empty?
			changed = true
			self.display_caches.where('schedule_id IN (?)', remove).delete_all
		end
		
		if !thecache.empty?
			changed = true
			thecache.each do |schedule_id|
				self.display_caches.build(:schedule_id => schedule_id)
			end
		end
		
		
		#
		# See if anything has changed?
		#
		if changed || force
			#
			# Invalidate the cache
			#
			self.last_updated = thetime
			self.save!(:validate => false)	# We want to raise an error as the job will re-run
		end
	end
	
	
	protected
	
	
	def check_time_zone
		if self.timezone_changed?
			Delayed::Job.enqueue ScheduleDisplayTimezone.new(self.id), :queue => 'schedule', :run_at => 2.seconds.from_now unless self.id.nil?
		end
	end


	def norm_display_url
		m = /\w[\w\/\-]*\w/.match(self.permalink.gsub(/[^(\w|\/|\-)]/, '_'))
		if m.length == 0
			self.errors.add :permalink, 'invalid custom URL for display'
		else
			self.permalink = m[0]
		end
	end

	
	validates_presence_of :name
	validate :norm_display_url, :if => Proc.new { |a| a.permalink.present? }
	validates_uniqueness_of :permalink, :allow_nil => true, :allow_blank => true	# Must be after normality validation
	validates_each :link do |record, attr, value|
		if !record.link.nil? && !record.link.empty? && value.index(URI::regexp(%w(http https))).nil?
			record.errors.add attr, I18n.t(:invalid_link_error)
		end
	end
end
