

OmniAuth.config.logger = Rails.logger
#OmniAuth.config.on_failure = Proc.new { |env|					# Un-comment To test failure in development mode
#	OmniAuth::FailureEndpoint.new(env).redirect_to_failure
#}

Rails.application.config.middleware.use OmniAuth::Builder do
	require 'openid/store/filesystem'
	
	provider :developer unless Rails.env.production?
	provider :twitter, ENV['TWITTER_KEY'], ENV['TWITTER_SECRET']
	#provider :google_oauth2, ENV['GOOGLE_KEY'], ENV['GOOGLE_SECRET']
	provider :facebook, ENV['FACEBOOK_ID'], ENV['FACEBOOK_SECRET'], {:client_options => {:ssl => {:ca_path => "/etc/ssl/certs"}}}
	provider :open_id, :store => OpenID::Store::Filesystem.new('/tmp')
	provider :google_apps, :store => OpenID::Store::Filesystem.new('/tmp')
	provider :identity, on_failed_registration: lambda { |env|
		IdentitiesController.action(:new).call(env)
	}
end
