class MonitorsController < ApplicationController
	#
	# So admins can edit/help other users
	#	Potential here for an admin user to pretend to be a sys admin
	#	Would be very hard to do and would have to be an authenticated malicious admin
	#
	def switch_group
		raise SecurityTransgression unless current_user.system_admin || current_user.user_groups.where('group_id = ?', params[:group_select]).exists?
		session[:group] = params[:group_select].to_i
		session[:parent] = session[:group]
		
		redirect_to medias_path
	end
	
	
	def switch_subgroup
		raise SecurityTransgression unless (current_user.system_admin || current_permissions.admin?) && current_parent.self_and_descendants.where('id = ?', params[:subgroup_select]).exists?
		session[:group] = params[:subgroup_select].to_i
		
		redirect_to medias_path
	end
	
	
	#
	# Feedback form stuff
	#
	def new	# new form
	end
	
	
	def create	# Send feedback
		if params[:feedback][:type].present? && params[:feedback][:comment].present?
			recipients = User.where('system_admin = ? AND email IS NOT NULL AND email != ?', true, "").map {|user| user.email}
			
			UserMailer.send_feedback(recipients, params[:feedback][:name], session[:mail], params[:feedback][:comment], params[:feedback][:type]).deliver unless recipients.empty?
		else
			render :action => "fail"
		end
	end
	
end
