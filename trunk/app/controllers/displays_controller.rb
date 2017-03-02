class DisplaysController < ApplicationController
	respond_to :json, :js
	respond_to :html, :only => [:index, :present]
	respond_to :video, :only => [:present]
	
	
	# Currently only update is not protected? Risk? low :)
	include EnlightenObservers
	observer :audit_observer
	
	
	
	PLAYLIST_HASH = {
		:only => [:id, :random, :default_timeout],
		:include => {
			:published_medias => {
				:only => [:pub_ordinal, :pub_run_time, :pub_start_time, :pub_transition_effect],
				:include => {
					:media => {
						:only => [:id, :file_path, :media_type, :background, :interactive],
						:include => {
							:formats => {
								:only => [:file_path],
								:include => {
									:accepts_file => {:only => :mime}
								}
							},
							:plugin => {
								:only => [:can_play_to_end, :requires_data, :file_path]
							}
						}
					}
				}
			}
		}
	}
	
	
	def index
		@displays = Display.search(current_group, params[:search])
		@displays = apply_pagination(@displays, params, 'displays.created_at DESC')
		respond_with(@displays)
	end
	
	def show
		@display = Display.find(params[:id])
		
		respond_with(@display)
	end
	
	def present
		if params[:permalink].present?
			@display = Display.where(:permalink => params[:permalink]).first
		else
			@display = Display.find(params[:id])
		end
		
		if @display.nil? || (@display.permalink.present? && params[:permalink].nil?)
			raise ActiveRecord::RecordNotFound, "Looking for a display"
		end
		
		@display.touch(:last_seen) if request.format == 'manifest'	# this allows for monitoring
		
		if stale?(:last_modified => @display.last_updated.utc, :etag => @display.last_updated.to_i)	#  This should work - last_updated is all we care about
			respond_with(@display) do |format|
				format.html {
					@preview = !!params[:preview]
					render :layout => false
				}
				format.manifest { 	# Doesn't use manifest when html is loaded as a preview
					render :content_type => 'text/cache-manifest', :layout => false
				}
				format.json {
					render :json => {
						:last_updated => @display.last_updated,
						:physical => @display.physical,
						:forward_back => @display.forward_back,
						:geolocate => @display.geolocate,
						:max_space => @display.max_space,
						:api => @display.api,
						:live_playlists => @display.live_playlists.as_json(PLAYLIST_HASH),
						:display_groups => @display.display_groups.as_json({
							:only => [:id, :playlist_id]
						}),
						:live_schedules => @display.live_schedules.as_json({
							:only => [:do_start, :do_end],
							:include => {
								:schedule => {
									:only => [:id, :display_group_id, :exclusive, :emergency, :created_at, :playlist_id]
								}
							}
						})
					}
				}
			end
		end
	end
	
	def new
		@display = Display.new
		@display.timezone = @display.timezone(current_group)
		respond_with(@display)
	end
	
	def create
		@display = Display.new(params[:display])
		userdisplay = GroupDisplay.new
		userdisplay.group = current_group
		@display.timezone = @display.timezone(current_group)
		
		
		Display.transaction do
			if @display.save
				userdisplay.display = @display
				userdisplay.save
			end
		end
		
		respond_with(@display)
	end
	
	def edit
		@display = Display.find(params[:id])
		respond_with(@display)
	end
	
	def update
		@display = Display.find(params[:id])
		check_groupadmin unless @display.last_seen.nil?			# If the display has never been used then we will check for permissions
		@saved = @display.update_attributes(params[:display])
		
		respond_with(@display)
	end
	
	def destroy
		#
		# Can only destroy if a group admin or system admin
		#
		check_groupadmin
		userdisplays = GroupDisplay.where('display_id IN (?) AND group_id = ?', params[:items], current_group.id).destroy_all
		
		render :nothing => true, :layout => false
	end
end
