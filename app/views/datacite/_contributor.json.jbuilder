# frozen_string_literal: true

# locals: contributor, orcid_scheme, ror_scheme

case contributor&.class&.name
when 'Hash'
  if contributor[:name].present?
    json.name contributor[:name]
    json.nameType 'Organizational'
    json.contributorType 'HostingInstitution'

    if contributor[:ror].present?
      json.nameIdentifiers [{
        nameIdentifier: contributor[:ror],
        nameIdentifierScheme: 'ROR'
      }]
    end
  end

when 'Org'
  json.name contributor.name
  json.nameType 'Organizational'
  json.contributorType 'Producer'

  ror = contributor.identifier_for_scheme(scheme: ror_scheme) if ror_scheme.present?
  if ror.present?
    json.nameIdentifiers [{
      nameIdentifier: ror.value,
      nameIdentifierScheme: 'ROR'
    }]
  end

when 'Contributor', 'User'
  if contributor.is_a?(User)
    formatted_name = [contributor.surname, contributor.firstname].reject(&:blank?).join(', ')
    json.name formatted_name.presence || contributor.email
  elsif contributor.is_a?(Contributor) && contributor.roles.to_i.positive?
    json.name contributor.name

    datacite_role = 'ProjectManager' if contributor.project_administration?
    datacite_role = 'ProjectLeader' if datacite_role.nil? && contributor.investigation?
    datacite_role = 'DataCurator' if datacite_role.blank?
    json.contributorType datacite_role
  end

  json.nameType 'Personal'

  if contributor.respond_to?(:org) && contributor.org.present?
    json.affiliation do
      json.name contributor.org.name

      ror = contributor.org.identifier_for_scheme(scheme: ror_scheme) if ror_scheme.present?
      if ror.present?
        json.affiliationIdentifier ror.value
        json.affiliationIdentifierScheme 'ROR'
      end
    end
  end

  orcid = contributor.identifier_for_scheme(scheme: orcid_scheme) if orcid_scheme.present?
  if orcid.present?
    orcid_value = orcid.value.start_with?('http') ? orcid.value : "https://orcid.org/#{orcid.value}"
    json.nameIdentifiers [{
      nameIdentifier: orcid_value,
      nameIdentifierScheme: 'ORCID'
    }]
  end
end
