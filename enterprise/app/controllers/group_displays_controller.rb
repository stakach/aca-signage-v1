class GroupDisplaysController < ApplicationController
	
	respond_to :js
	before_filter :check_ownership
	before_filter :check_groupadmin
	
	#
	# which user would you like to share with?
	#
	def new
		@groupdisplay = GroupDisplay.new
		@groupdisplay.display_id = params[:display].to_i
		
		#
		# TODO:: we need a sub group finder method here maybe?
		# => Same as the user switcher? Or paginated, ie the group selection is a seperate request to this
		#
	end
	
	#
	# Share with user
	#
	def create
		#
		# Check they can share with the group
		# => TODO:: need to feedback error messages to the users
		#
		raise SecurityTransgression unless current_user.user_groups.where('group_id = ?', params[:group_display][:group_id]).exists?
		raise SecurityTransgression unless (current_user.system_admin || current_permissions.admin?) && current_parent.self_and_descendants.where('id = ?', params[:group_display][:subgroup_id]).exists? if params[:group_display][:subgroup_id].present?
		
		@groupdisplay = GroupDisplay.new(params[:group_display])
		@groupdisplay.group_id = params[:group_display][:subgroup_id].to_i if params[:group_display][:subgroup_id].present?
		
		@groupdisplay.save
	end
	
	
	protected
	
	
	def check_ownership
		display = params[:display] || params[:group_display][:display_id]
		raise SecurityTransgression unless GroupDisplay.where('group_id = ? AND display_id = ?', current_group.id, display).count > 0
	end
	
end
