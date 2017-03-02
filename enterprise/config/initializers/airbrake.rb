Airbrake.configure do |config|
	config.api_key = {
		:project => 'aca-signage-cloud',	# the identifier you specified for your project in Redmine
		:tracker => 'Bug',					# the name of your Tracker of choice in Redmine
		:api_key => '0c85',					# the key you generated before in Redmine (NOT YOUR HOPTOAD API KEY!)
		:category => 'Production Bug',		# the name of a ticket category (optional.)
		:assigned_to => 'steve',			# the login of a user the ticket should get assigned to by default (optional.)
		:environment => 'production',		# application environment, gets prepended to the issue's subject and is stored as a custom issue field. useful to distinguish errors on a test system from those on the production system (optional).
	}.to_yaml
	config.host = 'advanced.plan.io'		# the hostname your Redmine runs at
	config.port = 443						# the port your Redmine runs at
	config.secure = true					# sends data to your server via SSL (optional.)
end
