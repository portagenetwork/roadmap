# frozen_string_literal: true

# This initializer sets the allowed hosts for the app configuration.
# https://guides.rubyonrails.org/configuring.html#actiondispatch-hostauthorization
module AllowedHosts
  def self.add_allowed_hosts(config)
    # Convert comma-separated string to array
    hosts = Rails.application.secrets.dmproadmap_host.to_s.split(',').map(&:strip)
    hosts.each do |host|
      config.hosts << host
    end
  end
end

# Add the allowed hosts (unless in development or test environment)
AllowedHosts.add_allowed_hosts(Rails.application.config) unless Rails.env.in?(%w[development test])
