# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/mocks/plan_snapshot_values'

RSpec.describe PlanSnapshots::RdaJson do
  let(:rda_json) { PlanSnapshotValues.mock_rda_json }
  let(:reader) { described_class.new(rda_json: rda_json) }
  let(:dmp_json) { rda_json['dmp'] }

  describe '#contact' do
    let(:contact_json) { dmp_json['contact'] }
    describe '#affiliation' do
      let(:affiliation_json) { contact_json['affiliation'] }
      it 'returns the contact affiliation name' do
        expect(affiliation_json['name']).to be_present
        expect(reader.contact.affiliation.name).to eq(affiliation_json['name'])
      end
    end
    context 'when contact is absent' do
      let(:rda_json) do
        json = PlanSnapshotValues.mock_rda_json
        json['dmp'].delete('contact')
        json
      end

      it 'returns nil for affiliation name' do
        expect(reader.contact.affiliation.name).to be_nil
      end
    end
  end

  describe '#contributors' do
    let(:contributor_json) { dmp_json['contributor'] }

    def contributors_with_role(role_key)
      uri = PlanSnapshotValues::ROLE_URIS.fetch(role_key)
      contributor_json.select { |c| Array(c['role']).include?(uri) }
    end

    describe 'ROLE_URIS' do
      it 'matches the mock fixture role URIs' do
        expect(PlanSnapshots::RdaJson::Contributors::ROLE_URIS).to eq(PlanSnapshotValues::ROLE_URIS)
      end
    end

    describe '#with_role' do
      %i[data_curation investigation project_administration other].each do |role_key|
        it "returns only contributors matching #{role_key}" do
          expected = contributors_with_role(role_key)
          expect(expected).to be_present, "fixture must include a contributor with role #{role_key}"

          matches = reader.contributors.with_role(role_key)

          expect(matches.length).to eq(expected.length)
          expect(matches).to all(be_a(PlanSnapshots::RdaJson::Contributor))
          expect(matches.map(&:role)).to match_array(expected.map { |c| c['role'] })
        end
      end

      it 'raises an ArgumentError for an unknown role' do
        expect { reader.contributors.with_role(:nonexistent_role) }
          .to raise_error(ArgumentError, /unknown role/)
      end
    end

    describe '#contributor_id' do
      it 'returns the identifier for a contributor with an ORCID' do
        expected = contributor_json.find { |c| c['contributor_id'].present? }
        expect(expected).to be_present, 'fixture must include a contributor with a contributor_id'

        index = contributor_json.index(expected)
        contributor = reader.contributors.to_a[index]

        expect(expected['contributor_id']['type']).to be_present
        expect(expected['contributor_id']['identifier']).to be_present
        expect(contributor.contributor_id.type).to eq(expected['contributor_id']['type'])
        expect(contributor.contributor_id.identifier).to eq(expected['contributor_id']['identifier'])
      end

      it 'returns nil type/identifier when contributor_id is absent' do
        expected = contributor_json.find { |c| c['contributor_id'].blank? }
        expect(expected).to be_present, 'fixture must include a contributor without a contributor_id'

        index = contributor_json.index(expected)
        contributor = reader.contributors.to_a[index]

        expect(contributor.contributor_id.type).to be_nil
        expect(contributor.contributor_id.identifier).to be_nil
      end
    end

    context 'when contributor is absent' do
      let(:rda_json) do
        json = PlanSnapshotValues.mock_rda_json
        json['dmp'].delete('contributor')
        json
      end

      it 'returns an empty array for any role' do
        expect(reader.contributors.with_role(:data_curation)).to eq([])
      end
    end
  end

  describe '#description' do
    let(:description_json) { dmp_json['description'] }
    it 'returns dmp.description' do
      expect(description_json).to be_present
      expect(reader.description).to eq(description_json)
    end
  end

  describe '#dmp_id' do
    let(:dmp_id_json) { dmp_json['dmp_id'] }
    describe '#identifier' do
      it 'returns dmp_id.identifier' do
        expect(dmp_id_json['identifier']).to be_present
        expect(reader.dmp_id.identifier).to eq(dmp_id_json['identifier'])
      end
    end

    describe '#type' do
      it 'returns dmp_id.type' do
        expect(dmp_id_json['type']).to be_present
        expect(reader.dmp_id.type).to eq(dmp_id_json['type'])
      end
    end
  end

  describe '#project' do
    let(:project_json) { dmp_json['project'].first }
    describe '#start_date' do
      it 'returns the first project entry start date' do
        expect(project_json['start']).to be_present
        expect(reader.project.start_date).to eq(project_json['start'])
      end
    end

    describe '#end_date' do
      it 'returns the first project entry end date' do
        expect(project_json['end']).to be_present
        expect(reader.project.end_date).to eq(project_json['end'])
      end
    end

    describe '#funding' do
      let(:funding_json) { project_json['funding'].first }
      describe '#name' do
        it 'returns the first funding entry name' do
          expect(funding_json['name']).to be_present
          expect(reader.project.funding.name).to eq(funding_json['name'])
        end
      end

      describe '#grant_id' do
        let(:grant_id_json) { funding_json['grant_id'] }
        it 'returns grant_id.identifier' do
          expect(grant_id_json['identifier']).to be_present
          expect(reader.project.funding.grant_id.identifier).to eq(grant_id_json['identifier'])
        end

        it 'returns grant_id.type' do
          expect(grant_id_json['type']).to be_present
          expect(reader.project.funding.grant_id.type).to eq(grant_id_json['type'])
        end
      end

      context 'when funding is an empty array' do
        let(:rda_json) do
          json = PlanSnapshotValues.mock_rda_json
          json['dmp']['project'].first['funding'] = []
          json
        end

        it 'returns nil for name and grant_id fields' do
          expect(reader.project.funding.name).to be_nil
          expect(reader.project.funding.grant_id.identifier).to be_nil
          expect(reader.project.funding.grant_id.type).to be_nil
        end
      end

      context 'when funding is absent' do
        let(:rda_json) do
          json = PlanSnapshotValues.mock_rda_json
          json['dmp']['project'].first.delete('funding')
          json
        end

        it 'returns nil for name and grant_id fields' do
          expect(reader.project.funding.name).to be_nil
          expect(reader.project.funding.grant_id.identifier).to be_nil
          expect(reader.project.funding.grant_id.type).to be_nil
        end
      end
    end

    context 'when dmp.project is an empty array' do
      let(:rda_json) do
        json = PlanSnapshotValues.mock_rda_json
        json['dmp']['project'] = []
        json
      end

      it 'returns nil for start_date and end_date' do
        expect(reader.project.start_date).to be_nil
        expect(reader.project.end_date).to be_nil
      end

      it 'returns nil for funding fields' do
        expect(reader.project.funding.name).to be_nil
      end
    end

    context 'when dmp.project is absent' do
      let(:rda_json) do
        json = PlanSnapshotValues.mock_rda_json
        json['dmp'].delete('project')
        json
      end

      it 'returns nil for start_date and end_date' do
        expect(reader.project.start_date).to be_nil
        expect(reader.project.end_date).to be_nil
      end
    end
  end

  describe '#title' do
    it 'returns title' do
      expect(dmp_json['title']).to be_present
      expect(reader.title).to eq(dmp_json['title'])
    end
  end

  context 'when rda_json is missing expected keys' do
    let(:reader) { described_class.new(rda_json: {}) }

    it 'returns nil/empty defaults for all accessors' do
      expect(reader.title).to be_nil
      expect(reader.description).to be_nil
      expect(reader.dmp_id.identifier).to be_nil
      expect(reader.dmp_id.type).to be_nil
      expect(reader.contact.affiliation.name).to be_nil
      expect(reader.contributors.with_role(:data_curation)).to eq([])
      expect(reader.project.start_date).to be_nil
      expect(reader.project.end_date).to be_nil
      expect(reader.project.funding.name).to be_nil
    end
  end

  context 'when rda_json is nil' do
    let(:reader) { described_class.new(rda_json: nil) }

    it 'does not raise and returns nil/empty defaults' do
      expect(reader.dmp_id.identifier).to be_nil
      expect(reader.contact.affiliation.name).to be_nil
      expect(reader.contributors.with_role(:data_curation)).to eq([])
      expect(reader.project.funding.name).to be_nil
    end
  end
end
