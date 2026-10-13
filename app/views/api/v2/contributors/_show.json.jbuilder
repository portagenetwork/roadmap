# frozen_string_literal: true

# locals: contributor, is_contact, for_common_madmp_api

is_contact ||= false
for_common_madmp_api ||= false

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
# required identifier objects. For the Common-MaDMP Contract we use the
# contributor email as a compatibility fallback when ORCID is absent.
id = Api::V2::ContributorPresenter.contributor_id(
  contributor,
  for_common_madmp_api: for_common_madmp_api
)
if id.present?
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
