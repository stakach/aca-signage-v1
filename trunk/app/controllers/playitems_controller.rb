class PlayitemsController < ApplicationController
	respond_to :xml, :json, :js
	
	def show
		@playitem = PlaylistMedia.find(params[:id])
		@media = @playitem.media
		media_as_json(@media)
		respond_with(@playitem)
	end
	
	#
	# Assumes we are coming from the media URL if html request
	#
	def create
		media_ids = params[:medias]
		@playlist =  Playlist.find(params[:playlist_id])
		media_ids = GroupMedia.where('media_id IN (?) AND group_id = ?', media_ids, current_group.id).pluck(:id)
		
		PlaylistMedia.transaction do
			media_ids.each do |media_id|
				playitem = PlaylistMedia.new(:playlist_id => @playlist.id, :group_media_id => media_id)
				raise "Save error" unless playitem.save
			end
		end
		
		respond_with(@playlist) do |format|
			format.js { render :action => 'update_playlist', :layout => false }
		end
	end
	
	
	#
	# TODO: edit and update
	#
	def edit
		@playitem = PlaylistMedia.find(params[:id])
		@items = params[:items] || []
		respond_with(@playitem)
	end
	
	def update
		@playitem = PlaylistMedia.find(params[:id])
		@playlist = @playitem.playlist
		@playitems = true	# Prevents being made a droppable
	
		if params[:item].nil?
			@saved = @playitem.update_attributes(params[:playlist_media])
		else
			theupdate = {}
			if params[:playlist_media][:seconds].present? || params[:playlist_media][:minutes].present? || params[:playlist_media][:hours].present?
				@playitem.hours = params[:playlist_media][:hours] 	# Convert the breakdown into actual time
				@playitem.minutes = params[:playlist_media][:minutes]
				@playitem.seconds = params[:playlist_media][:seconds]
				theupdate[:run_time] = @playitem[:run_time]
			end
			if params[:playlist_media][:transition_effect].present?
				theupdate[:transition_effect] = params[:playlist_media][:transition_effect].to_i
			end
			
			if theupdate.length > 0
				theupdate[:updated_at] = Time.now
				@item_ids = params[:item][:ids].split(',')
				@items = PlaylistMedia.where('id IN (?)', @item_ids)
				@items.update_all(theupdate)
			end
			@saved = true
		end
		
		respond_with(@playitem)
	end
	
	
	#
	# Copy playlist items from one playlist to another
	#
	def copy
		playitems = PlaylistMedia.find(params[:items])
		@playlist = Playlist.find(params[:playlist])
		
		PlaylistMedia.transaction do
			playitems.each do |item|
				PlaylistMedia.create(item.attributes.merge({:playlist_id => @playlist.id, :id => nil, :published => false}))
			end
		end
		
		respond_with(@playlist) do |format|
			format.js { render :action => 'update_playlist', :layout => false }
		end
	end
	
	
	#
	# Move playlists from one to another
	#
	def move
		playitems = params[:items]
		@playlist = Playlist.find(params[:playlist])
		
		
		#
		# Good or bad? this can't fail :) (technically)
		#
		PlaylistMedia.where('id IN (?)', playitems).update_all(:playlist_id => @playlist.id, :published => false)
	
		
		respond_with(@playlist) do |format|
			format.js { render :action => 'update_playlist', :layout => false }
		end
	end
	
	
	#
	# order items in a playlist
	#
	def order
		playitems = params[:playitem]
		@playlist  = PlaylistMedia.find(playitems[0]).playlist
		@playitems = true	# Prevents being made a droppable
		
		PlaylistMedia.order_all(params[:playitem])

		respond_with(@playlist) do |format|
			format.js { render :action => 'update_playlist', :layout => false }
		end
	end
	
	
	#
	# Destroy playitems and redirect to playlist if HTML request
	#
	def destroy
		playitems = params[:items]
		@playlist  = PlaylistMedia.find(playitems[0]).playlist
		@playitems = true	# Prevents being made a droppable
		
		PlaylistMedia.where('id IN (?)', playitems).update_all(:deleted => true, :updated_at => Time.now)
		PlaylistMedia.where('id IN (?) AND deleted = ? AND published = ?', playitems, true, false).destroy_all	# Delete any that needed 

		respond_with(@playlist) do |format|
			format.js { render :action => 'update_playlist', :layout => false }
		end
	end
end
