

OmniAuth.config.logger = Rails.logger
#OmniAuth.config.on_failure = Proc.new { |env|					# Un-comment To test failure in development mode
#	OmniAuth::FailureEndpoint.new(env).redirect_to_failure
#}

Rails.application.config.middleware.use OmniAuth::Builder do
	require 'openid/store/filesystem'
	
	provider :developer unless Rails.env.production?
	provider :ldap, :title => "Riverview Login", 
					:host => "192.168.23.254",
					:port => 389,
					:method => :plain,
					:base => "cn=Users,dc=advancedcontrol,dc=com,dc=au",
					:uid => "sAMAccountName",
					:name_proc => Proc.new {|name| name.gsub(/@.*$/,'')},
					:bind_dn => "ADVANCEDCONTROL\\stakach",
					:password => '31J09st2'
	provider :identity, on_failed_registration: lambda { |env|
		IdentitiesController.action(:new).call(env)
	}
end
