# frozen_string_literal: true

# Helpers for PlanSnapshot-related test values and generators
module PlanSnapshotValues
  def self.random_md5
    Array.new(32) { ('a'..'f').to_a.concat(('0'..'9').to_a).sample }.join
  end

  def self.mock_rda_json
    {
      'dmp' => {
        'title' => 'Test Plan',
        'description' => 'A test plan description.',
        'language' => 'eng',
        'created' => '2026-05-20T00:00:00Z',
        'modified' => '2026-05-20T00:00:00Z'
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
end
