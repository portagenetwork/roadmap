# frozen_string_literal: true

# Helpers for PlanSnapshot-related test values and generators
module PlanSnapshotValues # rubocop:disable Metrics/ModuleLength
  ROLE_BASE_URL = Contributor::ONTOLOGY_BASE_URL
  ROLE_URIS = {
    data_curation: "#{ROLE_BASE_URL}data-curation",
    investigation: "#{ROLE_BASE_URL}investigation",
    project_administration: "#{ROLE_BASE_URL}project-administration",
    other: 'other'
  }.freeze

  def self.mock_rda_json(type: 'url', identifier: mock_plan_identifier_url)
    {
      'dmp' => {
        'title' => 'Test Plan',
        'description' => 'A test plan description.',
        'language' => 'eng',
        'created' => '2026-05-20T00:00:00Z',
        'modified' => '2026-05-20T00:00:00Z',
        'contact' => mock_contact,
        'contributor' => mock_contributors,
        'project' => [
          {
            'start' => '2026-06-01T00:00:00Z',
            'end' => '2026-12-31T00:00:00Z',
            'funding' => [mock_funding]
          }
        ],
        'dmp_id' => mock_dmp_id(type: type, identifier: identifier)
      }
    }
  end

  def self.mock_extension_json
    {
      'extension' => [
        {
          'dmproadmap' => {
            'template' => {
              'id' => 1,
              'title' => 'Test Template'
            }
          },
          'complete_plan' => [mock_complete_plan_item]
        }
      ]
    }
  end

  def self.mock_complete_plan_item
    {
      'title' => 'Project details',
      'answer' => 'Example answer',
      'section' => 'General Information',
      'question' => 'What is the project about?',
      'question_id' => 1
    }
  end

  def self.mock_dmp_id(type: 'url', identifier: mock_plan_identifier_url)
    {
      'type' => type,
      'identifier' => identifier
    }
  end

  def self.mock_plan_identifier_url
    'http://example.org/api/v2/plans/18244'
  end

  def self.mock_contact(affiliation_name: mock_affiliation_name)
    {
      'name' => 'Jane Doe',
      'mbox' => 'jane.doe@example.org',
      'affiliation' => mock_affiliation(name: affiliation_name)
    }
  end

  def self.mock_contributors
    [
      mock_contributor(name: 'Alice Curator',
                       role: [ROLE_URIS[:data_curation]]),
      mock_contributor(name: 'Bob Investigator',
                       role: [ROLE_URIS[:investigation]]),
      mock_contributor(name: 'Carol Admin',
                       role: [ROLE_URIS[:project_administration]]),
      mock_contributor(name: 'Arthur Other',
                       role: [ROLE_URIS[:other]],
                       contributor_id: nil)
    ]
  end

  def self.mock_contributor(name: 'Alice Curator',
                            role: ['other'],
                            affiliation_name: mock_affiliation_name,
                            contributor_id: mock_contributor_id)
    {
      'name' => name,
      'role' => role,
      'affiliation' => mock_affiliation(name: affiliation_name),
      'contributor_id' => contributor_id
    }
  end

  def self.mock_contributor_id(type: 'orcid', identifier: '0000-0001-2345-6789')
    {
      'type' => type,
      'identifier' => identifier
    }
  end

  def self.mock_affiliation(name: mock_affiliation_name)
    {
      'name' => name
    }
  end

  def self.mock_affiliation_name
    'Test University'
  end

  def self.mock_funding(name: 'Test Funder', grant_id_type: 'url', grant_id_identifier: mock_grant_id_identifier)
    {
      'name' => name,
      'grant_id' => {
        'type' => grant_id_type,
        'identifier' => grant_id_identifier
      }
    }
  end

  def self.mock_grant_id_identifier
    'http://example.org/api/v2/grants/456'
  end
end
