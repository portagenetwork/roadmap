# frozen_string_literal: true

RSpec.shared_context 'with datacite configuration' do
  before do
    config = Rails.configuration.x.datacite
    config.active = true
    config.api_base_url = 'https://api.test.datacite.org' if config.api_base_url.blank?
    config.repository_id = 'MY_REPO' if config.repository_id.blank?
    config.password = 'SECRET' if config.password.blank?
  end
end
