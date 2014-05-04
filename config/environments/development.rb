Hoshinplan::Application.configure do
  # Hobo: tell ActiveReload about dryml
  config.watchable_dirs[File.join(config.root, 'app/views')] = ['dryml']
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false
  
  #config.hobo.show_translation_keys = true 

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true 
  config.action_controller.perform_caching = false
  config.cache_store = :redis_store, 'redis://rediscloud:E2rOg7rZl9fIpgtp@pub-redis-18280.eu-west-1-1.2.ec2.garantiadata.com:18280', { :expires_in => 90.minutes }
  config.hobo.stable_cache_store = :redis_store, 'redis://rediscloud:E2rOg7rZl9fIpgtp@pub-redis-18280.eu-west-1-1.2.ec2.garantiadata.com:18280'


  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true
config.action_mailer.delivery_method = :sendmail
# Defaults to:
# config.action_mailer.sendmail_settings = {
#   :location => '/usr/sbin/sendmail',
#   :arguments => '-i -t'
# }
config.action_mailer.raise_delivery_errors = true
config.action_mailer.asset_host = 'http://localhost:5000'
config.action_mailer.default_url_options = { host: 'localhost:5000', only_path: false }



  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  config.active_record.auto_explain_threshold_in_seconds = 0.5

  # Do not compress assets
  config.assets.compress = false
  config.assets.css_compressor = :yui
  config.assets.js_compressor = :uglify

  # Expands the lines which load the assets
  config.assets.debug = true
  config.paperclip_defaults = {
    :storage => :s3,
    :s3_credentials => {
      :bucket => ENV['S3_BUCKET_NAME'],
      :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
      :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
    }
  }
end
