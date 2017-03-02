class SchedulesController < ApplicationController
	respond_to :xml, :json, :js
	
	
	include EnlightenObservers
	observer :audit_observer
	
	before_filter :check_publisher, :except => :show
	
	
	def show	# Note:: params[:id] is the display group id
		tzone = params[:timezone]
		
		#
		# We need to get the times for these in UTC and then
		#	check if there are any that need to be displayed an exact time
		#	relative to the users timezone
		#
		begin
			Time.zone = tzone	# Calendar sends start and end dates in user computers timezone
		
			calstart = Time.zone.at(params[:start].to_i)
			calend = Time.zone.at(params[:end].to_i)
		ensure
			Time.zone = 'Etc/GMT+12'
		end
		
		#
		# Generate the event objects to be JSONised
		#
		@events = Schedule.get_events(params[:id], calstart, calend, tzone)
		
		respond_with(@events)
	end
	
	
	def new
		@schedule = Schedule.new
		
		begin
			Time.zone = 'UTC'	# This is the timezone that the calendar sends us the times in
			@schedule.do_start = DateTime.parse(params[:start])
			@schedule.do_end = DateTime.parse(params[:end])
		ensure
			Time.zone = 'Etc/GMT+12'
		end
		
		@schedule.playlist_id = params[:playlist_id].to_i
		@schedule.display_group_id = params[:group_id].to_i
		@schedule.all_day = params[:all_day]
		
		respond_with(@schedule)
	end
	
	def create
		@schedule = Schedule.new(params[:schedule])
		
		if @schedule.sync_all_zones
			@schedule.all_day = false
			zone = params[:timezone]
			@schedule.do_start = @schedule.do_start.new_zone(zone)
			@schedule.do_end = @schedule.do_end.new_zone(zone)
			@schedule.end_repeat = @schedule.end_repeat.new_zone(zone) unless @schedule.end_repeat.nil?
		end
		@schedule.save
		
		respond_with(@schedule)
	end
	
	
	def edit
		@schedule = Schedule.find(params[:id])
		
		#
		# Synced zones need to be moved into the current time zone and saved as a local time
		#
		if @schedule.sync_all_zones
			@zone = params[:timezone]
			#@schedule.do_start = @schedule.do_start.in_time_zone(@zone)	# TODO:: When we move to JSON only responses we need to uncomment this
			#@schedule.do_end = @schedule.do_end.in_time_zone(@zone)		# Mother-fucking rails messing up my form!!! argh
			#@schedule.end_repeat = @schedule.end_repeat.in_time_zone(@zone) unless @schedule.end_repeat.nil?
		end
		
		respond_with(@schedule)
	end
	
	def update
		@schedule = Schedule.find(params[:id])
		@schedule.attributes = params[:schedule]		# Update the attributes
		
		#
		# fix the timezones here
		#
		if @schedule.sync_all_zones
			@schedule.all_day = false
			zone = params[:timezone]
			@schedule.do_start = @schedule.do_start.new_zone(zone)
			@schedule.do_end = @schedule.do_end.new_zone(zone)
			@schedule.end_repeat = @schedule.end_repeat.new_zone(zone) unless @schedule.end_repeat.nil?
		end
		flash[:notice] = "#{t(:schedule)} #{t(:update_success)}." if @schedule.save
		
		respond_with(@schedule)
	end
	
	
	def update_move	# Updates a dragging of the event to another day or start time
		@schedule = Schedule.find(params[:id])
		daychange = params[:daychange].to_i || 0
		minchange = params[:minchange].to_i || 0
		@schedule.do_start += daychange.days
		@schedule.do_end += daychange.days
		@schedule.do_start += minchange.minutes
		@schedule.do_end += minchange.minutes
		
		if params[:allday] == 'true'
			do_start = @schedule.do_start
			do_end = @schedule.do_end
			
			if @schedule.sync_all_zones
				tzone = params[:timezone]
				do_start = @schedule.do_start.in_time_zone(tzone)
				do_end = @schedule.do_end.in_time_zone(tzone)
				
				@schedule.all_day = false
			else
				@schedule.all_day = true
			end
			
			do_start = do_start - do_start.hour.hours	# makes sure start at 00:00
			do_start = do_start - do_start.min.minutes
			@schedule.do_start = do_start
			do_end = do_end + (23 - do_end.hour).hours	# makes sure ends at 23:59
			do_end = do_end + (59 - do_end.min).minutes
			@schedule.do_end = do_end
		elsif params[:allday] == 'false'
			@schedule.all_day = false
		end
		
		@schedule.save!			# throw an error if this fails for the browser to deal with
		
		respond_with(@schedule) do |format|
			format.js { render :nothing => true, :layout => false }
		end
	end
	
	
	def update_runtime	# Updates a re-sizing of the event
		@schedule = Schedule.find(params[:id])
		daychange = params[:daychange].to_i || 0
		minchange = params[:minchange].to_i || 0
		@schedule.do_end += daychange.days
		@schedule.do_end += minchange.minutes
		
		@schedule.save!			# throw an error if this fails for the browser to deal with
		
		respond_with(@schedule) do |format|
			format.js { render :nothing => true, :layout => false }
		end
	end
	
	
	def destroy
		@schedule = Schedule.find(params[:id])
		@schedule.destroy
		raise "Delete Failed" unless @schedule.destroyed?
		
		respond_with(@schedule) do |format|
			format.js { render :nothing => true, :layout => false }
		end
	end
	
	
	protected
	
	def updated_zones(schedule, zone)
		if !@schedule.sync_all_zones
			
		end
	end
end
