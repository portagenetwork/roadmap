# frozen_string_literal: true

# Helper methods for Orgs
module OrgsHelper
  # The preferred logo url for the current configuration. If DRAGONFLY_AWS is true, return
  # the remote_url, otherwise return the url
  def logo_url_for_org(org)
    if ENV.fetch('DRAGONFLY_AWS', nil) == 'true'
      org.logo.remote_url
    else
      org.logo.url
    end
  end
end
