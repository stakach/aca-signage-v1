class PlaylistsController < ApplicationController
	respond_to :json, :js
	respond_to :html, :only => [:show, :destroy, :preview]
	
	include EnlightenObservers
	observer :audit_observer
	before_filter :user_check, :only => [:show, :preview, :footer, :edit, :update, :publish, :destroy, :move]
	before_filter :check_publisher, :only => [:publish]
	
	
	def show
		#@playlist = Playlist.find(params[:id])
		@playitems = @playlist.search(params[:search])
		@playitems = apply_pagination(@playitems, params, nil)
		respond_with(@playitems)
	end
	
	
	def preview
		#@playlist = Playlist.find(params[:id])
		respond_with(@playlist) do |format|
			format.html { render :layout => false }
			format.json {
				items = []
				@playlist.preview_medias.includes(:media).each do |content|
					items << {
						:pub_ordinal => content.ordinal,
						:pub_run_time => content[:run_time],
						:pub_start_time => content.start_time,
						:pub_transition_effect => content.transition_effect,
						:media => content.media.as_json({
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
						})
					}
				end
				render :json => {
					:last_updated => @playlist.last_updated,
					:physical => false,
					:live_playlists => [{
						:id => @playlist.id,
						:random => false,
						:default_timeout => @playlist.default_timeout,
						:published_medias => items
					}],
					:display_groups => [{
						:id => 1,
						:playlist_id => @playlist.id,
					}],
					:live_schedules => []
				}
			}
		end
	end
	
	def footer
		#@playlist = Playlist.find(params[:id])
		respond_with(@playlist)
	end
	
	def new
		@playlist = Playlist.new
		respond_with(@playlist)
	end
	
	def create
		@playlist = Playlist.new(params[:playlist].merge({:group_id => current_group.id}))
		
		@playlist.save
		
		respond_with(@playlist)
	end
	
	def edit
		#@playlist = Playlist.find(params[:id])
		respond_with(@playlist)
	end
	
	def update
		check_publisher if @playlist.published_medias.exists?
		
		#@playlist = Playlist.find(params[:id])
		@playitems = true	# Ensures this playlist element is selected
		@saved = @playlist.update_attributes(params[:playlist])
		respond_with(@playlist)
	end
	
	def publish
		#@playlist = Playlist.find(params[:id])
		
		if !params[:selected].nil?
			@playitems = true	# Prevents being made a droppable and updates the view
		end
		
		if params[:undo].nil?
			@playlist.publish
		else
			@playlist.cancel_publish
		end
		
		respond_with(@playlist)
	end
	
	def destroy
		check_publisher if @playlist.published_medias.exists?
		
		@playlist.destroy
		
		flash[:notice] = "#{t(:playlist_deleted)}." if @playlist.destroyed?
		respond_with(@playlist) do |format|
			format.html { redirect_to medias_path }
		end
	end
	
	def move
		if !params[:group_id].nil?
			@playlist.display_group_id = params[:group_id].to_i
		else
			@playlist.display_group_id = nil
		end
		
		@playlist.save!
		
		render :nothing => true, :layout => false
	end
	
	
	protected
	
	
	def user_check
		@playlist = Playlist.find(params[:id])
		raise SecurityTransgression unless @playlist.group_id == current_group.id
	end
end
