class UserMailer < ActionMailer::Base
	default :from => "signage@advancedcontrol.com.au"
	
	def send_feedback(recipients, user_name, user_email, user_comments, tracker)
		@comments = user_comments
		@name = user_name
		@email = user_email
		@tracker = tracker
		#recipients = User.where('admin = ? AND status & ? > 0', true, User::SYSTEM_ADMIN).map {|user| user.email}
		mail(:to => recipients, :subject => "#{t(:email_feedback_from)} #{user_name.empty? ? user_email : user_name} @ v3.1")
	end
	
	
	#
	# TODO:: Display warnings in multiple languages (Requires DB level info)
	#
	def send_alert(display)
		@display = display
		recipients = User.alerts_for(display).map{|user| user.email}
		mail(:to => recipients, :subject => "Signage Display Warning")
	end
end
