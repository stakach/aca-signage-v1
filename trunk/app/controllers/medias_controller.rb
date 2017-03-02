class MediasController < ApplicationController
	respond_to :xml, :json, :js
	respond_to :html, :only => [:index, :create]
	
	
	include EnlightenObservers
	observer :audit_observer
	before_filter :user_check, :only => [:show, :row, :edit, :update, :destroy, :error_retry]
	


	def index
		@medias = Media.search(current_group, params[:search])
		@medias = apply_pagination(@medias, params, 'created_at DESC')
		
		respond_with(@medias)
	end
	
	def row
		#@media = Media.find(params[:id])
		respond_with(@media)
	end
	
	def show
		#@media = Media.find(params[:id])
		media_as_json(@media)
		respond_with(@media)
	end
	
	
	def new
		@media = Media.new
		respond_with(@media)
	end
	
	
	#
	# Error means that either the url or file could not be used
	#
	def create
		uploaded_file = params[:media].delete(:uploaded_file)	# We need user_id to be assigned before we start processing the file
		uri = params[:media].delete(:url_path)					# avoid name field overwrite
		@media = Media.new(params[:media].merge({:user_id => current_user.id}))
		
		if uploaded_file.present?
			@media.uploaded_file = uploaded_file
		elsif uri.present?
			@media.url_path = uri
		end
		
		gm = GroupMedia.new
		gm.group = current_group
		
		begin
			Media.transaction do
				@media.save!
				gm.media = @media
				gm.save!
			end
		rescue
		end
		
		minimal_response(@media)
	end
	
	def edit
		#@media = Media.find(params[:id])
		respond_with(@media)
	end
	
	def update
		#@media = Media.find(params[:id])
		check_publisher if @media.playlist_medias.exists?

		@saved = @media.update_attributes(params[:media])
		media_as_json(@media)
		respond_with(@media)
	end
	
	def destroy
		check_publisher if @media.playlist_medias.exists?
		
		@media.destroy
		raise "Delete Failed" unless @media.destroyed?

		respond_with(@media) do |format|
			format.js { render :nothing => true, :layout => false }
		end
	end
	
	
	#
	# Retry a particular conversion
	#
	def error_retry
		#@media = Media.find(params[:id])
		
		if [:error, :invalid].include? @media.workflow_state.to_sym
			@media.workflow_state = 'checking'
			@media.media_type = nil
			@media.save!
		end
		
		@media.check_media
	end
	
	
	protected
	
	
	def user_check
		@media = GroupMedia.includes(:media).where({:group_id => current_group.id, :media_id => params[:id]}).first.media
	rescue
		raise SecurityTransgression	# The media item was probably deleted
	end
	
end
