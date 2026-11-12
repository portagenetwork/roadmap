# frozen_string_literal: true

Recaptcha.configure do |config|
  config.site_key = Rails.configuration.x.sealed_secrets.recaptcha_site_key
  config.secret_key = Rails.configuration.x.sealed_secrets.recaptcha_secret_key
  #   config.proxy = Rails.configuration.x.sealed_secrets.recaptcha_proxy
end
