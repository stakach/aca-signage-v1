class InviteMailer < ActionMailer::Base
	default :from => "signage@advancedcontrol.com.au"
	
	
	def invite_email(invite)
		@group = invite.group.description
		@message = invite.message
		@url  = invite_url(:id => invite.id, :secret => invite.secret)
		mail(:to => invite.email, :subject => "Invite to signage group")
	end
end
