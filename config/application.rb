# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_mailbox/engine'
require 'action_text/engine'
require 'action_view/railtie'
require 'action_cable/engine'
require 'view_component/engine'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Scholarsphere
  class Application < Rails::Application
    require 'healthchecks'
    require 'scholarsphere/redis_config'
    require 'scholarsphere/solr_config'
    require 'json_log_formatter'
    require 'qa/authorities/persons'
    require 'qa/authorities/users'

    def read_only?
      ENV['READ_ONLY'] == 'true'
    end

    config.generators { |generator| generator.test_framework :rspec }
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    config.admin_group = ENV.fetch('ADMIN_GROUP', 'umg-up.dlt.scholarsphere-admin')

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.redis = Scholarsphere::RedisConfig.new.to_hash
    config.solr = Scholarsphere::SolrConfig.new

    # ActiveJob config
    config.active_job.queue_adapter = :sidekiq

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.time_zone = 'Eastern Time (US & Canada)'

    config.view_component.default_preview_layout = 'component_preview'

    config.no_reply_email = ENV.fetch('NO_REPLY_EMAIL', 'no_reply@scholarsphere.psu.edu')
    config.incident_email = ENV.fetch('INCIDENT_EMAIL', 'no_reply@scholarsphere.psu.edu')
    config.subject_prefix = ENV.fetch('SUBJECT_PREFIX', 'ScholarSphere Contact Form -')

    # Use our own custom exceptions
    config.exceptions_app = routes
  end
end
