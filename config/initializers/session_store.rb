# frozen_string_literal: true

session_options = { key: "_meerkat_session" }

if Rails.env.production?
  # Share login/onboarding session between meerkatagents.com and cloud.meerkatagents.com
  session_options[:domain] = ".meerkatagents.com"
  session_options[:secure] = true
  session_options[:same_site] = :lax
end

Rails.application.config.session_store :cookie_store, **session_options
