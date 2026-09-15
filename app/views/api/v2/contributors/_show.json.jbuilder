# frozen_string_literal: true

# locals: contributor, is_contact

is_contact ||= false

name = contributor.is_a?(User) ? contributor.name(false) : contributor.name
json.name sanitize(name)
json.mbox contributor.email

if !is_contact && contributor.selected_roles.any?
  roles = contributor.selected_roles.map do |role|
    Api::V2::ContributorPresenter.role_as_uri(role: role)
  end
  json.role roles if roles.any?
end

if contributor.org.present?
  json.affiliation do
    json.partial! 'api/v2/orgs/show', org: contributor.org
  end
end

# NOTE: The Common-MaDMP schema treats contact_id and contributor_id as
# required identifier objects. In practice we only populate them when ORCID is
# present, so records without ORCID currently omit a required field.
# If we need a fallback, email/mbox may be the only available app-level value,
# but that is a compatibility fallback rather than a true identifier type.
orcid = contributor.identifier_for_scheme(scheme: 'orcid')
if orcid.present?
  id = Api::V2::ContributorPresenter.contributor_id(
    identifiers: contributor.identifiers
  )
  if is_contact
    json.contact_id do
      json.partial! 'api/v2/identifiers/show', identifier: id
    end
  else
    json.contributor_id do
      json.partial! 'api/v2/identifiers/show', identifier: id
    end
  end
end
