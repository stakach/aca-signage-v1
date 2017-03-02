
#
# This will monitor key events and save them into the history table for tracking who is doing what
#
# Create, Delete, Update
#	media			- what is being uploaded
#	schedules		- what is being displayed
#	display_groups	- playlist change (what is being displayed)
#	playlists		- Who is updating what is being displayed
#
class AuditObserver < ActiveRecord::Observer

	observe :display_group, :media, :playlist, :schedule, :display
	
	def after_create(record)	# must be logged on to create
		return unless user_action
		return if record.new_record?
		History.new.do_audit(record, :create, controller.session[:user])
	end
	
	def after_update(record)
		return unless user_action
		
		#
		# Lets check the update relates to attributes we care about
		#
		return if (record.changed - ['updated_at','created_at','workflow_state','content_type']).length == 0
		
		History.new.do_audit(record, :update, controller.session[:user])
	end
	
	def after_destroy(record)
		return unless user_action
		History.new.do_audit(record, :deleted, controller.session[:user])
	end
	
	
	protected
	
	
	#
	# Is a user currently logged on?
	#
	def user_action
		if controller.nil? || !controller.respond_to?(:session) || controller.session[:user].nil?
			return false
		end
		
		return true
	rescue
		return false
	end

end
