# frozen_string_literal: true

Rails.configuration.x.datacite.active = true
Rails.configuration.x.datacite.api_base_url = 'https://api.datacite.org'
Rails.configuration.x.datacite.test_api_base_url = 'https://api.test.datacite.org'

# Define an organization as the hosting institution for the DataCite record.
# Datacite defines this as:
#    "Typically, the organisation allowing the resource to be available on the
#     internet through the provision of its hardware/software/operating support."
Rails.configuration.x.datacite.hosting_institution = 'Digital Research Alliance of Canada'
Rails.configuration.x.datacite.hosting_institution_identifier = 'https://ror.org/010r6td27'

Rails.configuration.x.datacite.repository_id = Rails.application.secrets.datacite_repository_id
Rails.configuration.x.datacite.password      = Rails.application.secrets.datacite_password
Rails.configuration.x.datacite.shoulder      = Rails.application.secrets.datacite_shoulder
