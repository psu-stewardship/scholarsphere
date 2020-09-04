# frozen_string_literal: true

module Dashboard
  module WorkForm
    class BaseController < ::Dashboard::BaseController
      private

        def determine_layout
          'frontend'
        end

        def save_and_exit?
          params.key?(:save_and_exit)
        end

        def redirect_upon_success
          if save_and_exit?
            redirect_to dashboard_root_path,
                        notice: 'Work version was successfully updated.'
          else
            redirect_to next_page_path
          end
        end

        def next_page_path
          raise NotImplementedError, 'You must implement this method in your controller subclass'
        end
    end
  end
end
