Rails.application.config.session_store :cookie_store, key: '_scholarsphere', secure: Rails.env.production?, httponly: Rails.env.production?