# frozen_string_literal: true

# NB: `req` is a Rack::Request object (basically an env hash with friendly accessor methods)

# Progressive login throttling by IP.
# - Each throttle has its own counter and time window.
# - All matching throttles increment on every request.
# - A request is blocked if any throttle exceeds its limit.
LEVELS = [
  ['lowest', 5, 3.minutes],
  ['low', 10, 15.minutes],
  ['medium', 20, 2.hours],
  ['high', 50, 10.hours],
  ['highest', 100, 72.hours]
].freeze

# All paths that we will apply throttling to
PATHS = ['/users/sign_in', '/users/password'].freeze

# Enable/disable Rack::Attack
Rack::Attack.enabled = true

# Cache store required to work.
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new # defaults to Rails.cache

# Throttle should send a 429 Error response code and display public/429.html
Rack::Attack.throttled_responder = lambda do |_env|
  html = ActionView::Base.empty.render(file: 'public/429.html')
  [429, { 'Content-Type' => 'text/html' }, [html]]
end

unless Rails.env.test?
  # Create a throttle for each (path, level) pairing
  PATHS.each do |path|
    LEVELS.each do |name, limit, period|
      Rack::Attack.throttle("#{path} #{name}", limit: limit, period: period) do |req|
        req.post? && req.path == path && req.ip
      end
    end
  end
end
