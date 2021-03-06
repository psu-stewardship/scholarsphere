# frozen_string_literal: true

class WorkVersions::VersionNavigationComponent < ApplicationComponent
  include Rails.application.routes.url_helpers

  attr_writer :navigable_policy_source

  def initialize(work:, current_version:)
    @work = work
    @current_version = current_version
  end

  private

    attr_reader :work,
                :current_version

    def version_options
      work
        .decorated_versions
        .reverse
        .filter { |version| show_version?(version) }
        .map do |version|
        [
          version,
          path_for(version),
          list_classes_for(version),
          link_classes_for(version)
        ]
      end
    end

    def path_for(version)
      if work.latest_published_version.uuid == version.uuid
        resource_path(work.uuid)
      else
        resource_path(version.uuid)
      end
    end

    def list_classes_for(version)
      'active' if current?(version)
    end

    def link_classes_for(version)
      'disabled' if current?(version)
    end

    def current?(version)
      current_version.uuid == version.uuid
    end

    def show_version?(decorated_version)
      current?(decorated_version) || navigable?(decorated_version)
    end

    # Components can call view helpers through the `helpers` method, as is done in
    # the body of the lambda below. However, the one below to retrieve the pundit
    # policy relies on current_user, which also relies on having Warden up and
    # running. This is no problem in the actual environment, but in unit tests
    # it's not available. We can use stubbing to get around this during tests.
    def navigable?(decorated_version)
      undecorated_version = decorated_version.to_model

      helpers.policy(undecorated_version).navigable?
    end
end
