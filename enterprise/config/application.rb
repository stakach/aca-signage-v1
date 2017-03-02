require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require *Rails.groups(:assets => %w(development test))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Signage
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
	config.autoload_paths += %W(#{config.root}/app/observers)
	config.autoload_paths += %W(#{config.root}/app/jobs)
	
	config.assets.precompile += ['auth_sources.js', 'converters.js', 'displays.js', 'groups.js', 'medias.js',
								'playlists.js', 'plugins.js', 'sub_groups.js', 'ug.js', 'users.js', 'player/signage.js',
								'player/signage.worker.emulator.js', 'player/signage.worker.js',
								'locales/core-en.js', 'locales/auth_sources-en.js', 'locales/converters-en.js',
								'locales/displays-en.js', 'locales/groups-en.js', 'locales/medias-en.js', 'locales/playlists-en.js',
								'locales/sub_groups-en.js', 'locales/users-en.js']

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Etc/GMT+12'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable the asset pipeline
    config.assets.enabled = true
    config.assets.paths << "#{Rails.root}/app/assets/javascripts/player"
    config.assets.paths << "#{Rails.root}/app/assets/javascripts/locales"
    config.assets.paths << "#{Rails.root}/app/assets/javascripts/lib"

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.8'
  end
end
