# frozen_string_literal: true

# Helpers for PlanSnapshot-related test values and generators
module PlanSnapshotValues
  def self.random_md5
    Array.new(32) { ('a'..'f').to_a.concat(('0'..'9').to_a).sample }.join
  end

  def self.mock_rda_json(type: 'url', identifier: mock_plan_identifier_url)
    {
      'dmp' => {
        'title' => 'Test Plan',
        'description' => 'A test plan description.',
        'language' => 'eng',
        'created' => '2026-05-20T00:00:00Z',
        'modified' => '2026-05-20T00:00:00Z',
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
          }
        }
      ]
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
end
