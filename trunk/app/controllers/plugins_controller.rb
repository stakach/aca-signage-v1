class PluginsController < ApplicationController
	
	
	respond_to :json
	before_filter :user_check, :only => [:update, :destroy]
	
	
	def index
		@plugins = Plugin.search(current_group, params[:search])
		@plugins = apply_pagination(@plugins, params, 'name DESC')
		respond_with(@plugins)
	end
	
	def show
		#
		# TODO:: check that this plugin is available to the current user (group admin or system admin)
		#
		@plugin = Plugin.find(params[:id])
		common_response(@plugin)	# defined in application
	end
	
	def create
		#
		# TODO:: Check the current user is a group admin or system admin
		#
		@plugin = Plugin.new(params[:plugin])
		@plugin.save
		common_response(@plugin)	# defined in application
	end
	
	def update
		#
		#TODO:: check that this plugin is available to the current user (group admin or system admin)
		# user_check (sets @plugin in before filter)
		@plugin.update_attributes(params[:plugin])
		common_response(@plugin)
	end
	
	def destroy
		#
		#TODO:: check that this plugin is available to the current user (group admin or system admin)
		# user_check (sets @plugin in before filter)
		@plugin.destroy
		if @plugin.destroyed?
			render :json => @plugin
		else
			render :text => "{error:'Unable to delete plugin'}", :layout => false, :status => :internal_server_error
		end
	end
	
	
	protected
	
	
	def user_check
		@plugin = Plugin.find(params[:id])
		raise SecurityTransgression unless current_user.system_admin
	end
end
