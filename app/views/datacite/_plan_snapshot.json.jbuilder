# frozen_string_literal: true

json.ignore_nil!

json.data do # rubocop:disable Metrics/BlockLength
  json.type 'dois'

  json.attributes do # rubocop:disable Metrics/BlockLength
    json.prefix Rails.configuration.x.datacite.shoulder.to_s
    json.schemaVersion 'http://datacite.org/schema/kernel-4'
    json.event 'publish'

    json.types do
      json.resourceType 'Data Management Plan'
      json.resourceTypeGeneral 'OutputManagementPlan'
    end

    # Fetch schemes for identifiers
    ror_scheme = IdentifierScheme.find_by(name: 'ror')
    fundref_scheme = IdentifierScheme.find_by(name: 'fundref')
    orcid_scheme = IdentifierScheme.find_by(name: 'orcid')

    # 1. Creators (Owners & Co-owners)
    creators = plan.owner_and_coowners
    if creators.present?
      json.creators creators do |creator|
        json.partial! 'datacite/contributor', contributor: creator,
                                              orcid_scheme: orcid_scheme,
                                              ror_scheme: ror_scheme
      end
    end

    # 2. Contributors & Hosting Institution
    contributors = plan.contributors.to_a
    contributors << plan.org if plan.org.present?

    contributors << {
      name: Rails.configuration.x.datacite.hosting_institution,
      ror: Rails.configuration.x.datacite.hosting_institution_identifier
    }

    json.contributors contributors do |contributor|
      json.partial! 'datacite/contributor', contributor: contributor,
                                            orcid_scheme: orcid_scheme,
                                            ror_scheme: ror_scheme
    end

    # 3. Titles & Core Metadata
    json.titles [{ title: is_canonical ? plan.title : snapshot.title }]
    json.publisher ApplicationService.application_name
    json.publicationYear Time.current.year

    # 4. Timestamps
    json.dates [
      { type: 'Created', date: snapshot.created_at.iso8601 },
      { type: 'Updated', date: snapshot.updated_at.iso8601 }
    ] do |hash|
      json.date hash[:date]
      json.dateType hash[:type]
    end

    # 5. Abstract / Description
    if plan.description.present?
      json.descriptions [{
        description: plan.description,
        descriptionType: 'Abstract'
      }] do |desc|
        json.description desc[:description]
        json.descriptionType desc[:descriptionType]
      end
    end

    # 6. Version Relationships
    related = []

    if is_canonical
      # Canonical DOI links to all child snapshot DOIs via HasVersion
      if local_assigns[:has_version_dois].present?
        local_assigns[:has_version_dois].each do |snap_doi|
          related << {
            relatedIdentifier: snap_doi,
            relatedIdentifierType: 'DOI',
            relationType: 'HasVersion'
          }
        end
      end
    else
      # Snapshot DOI links to Canonical (IsVersionOf) and Prior Snapshot (IsNewVersionOf)
      if canonical_doi.present?
        related << {
          relatedIdentifier: canonical_doi,
          relatedIdentifierType: 'DOI',
          relationType: 'IsVersionOf'
        }
      end

      if previous_doi.present?
        related << {
          relatedIdentifier: previous_doi,
          relatedIdentifierType: 'DOI',
          relationType: 'IsNewVersionOf'
        }
      end
    end

    json.relatedIdentifiers related if related.any?

    # 7. Funding References & Grant Info
    if plan.funder.present?
      json.fundingReferences [plan.funder] do |funder|
        json.funderName funder.name

        fundref = funder.identifier_for_scheme(scheme: fundref_scheme) if fundref_scheme.present?
        if fundref.present?
          json.funderIdentifier fundref.value
          json.funderIdentifierType 'Crossref Funder'
        end

        if plan.grant.present?
          json.awardURI plan.grant.value if plan.grant.value.to_s.start_with?('http')
          json.awardNumber plan.grant.value
        end
      end
    end
  end
end
