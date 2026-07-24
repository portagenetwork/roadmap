# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/mocks/plan_snapshot_values'

RSpec.describe PlanSnapshots::RdaJson do
  let(:rda_json) { PlanSnapshotValues.mock_rda_json }
  let(:reader) { described_class.new(rda_json: rda_json) }
  let(:dmp_json) { rda_json['dmp'] }

  describe '#title' do
    it 'returns title' do
      expect(reader.title).to eq(dmp_json['title'])
    end
  end

  describe '#dmp_id' do
    let(:dmp_id_json) { dmp_json['dmp_id'] }
    describe '#identifier' do
      it 'returns dmp_id.identifier' do
        expect(reader.dmp_id.identifier).to eq(dmp_id_json['identifier'])
      end
    end

    describe '#type' do
      it 'returns dmp_id.type' do
        expect(reader.dmp_id.type).to eq(dmp_id_json['type'])
      end
    end
  end

  describe '#project' do
    let(:project_json) { dmp_json['project'].first }

    describe '#start_date' do
      it 'returns the first project entry start date' do
        expect(reader.project.start_date).to eq(project_json['start'])
      end
    end

    describe '#end_date' do
      it 'returns the first project entry end date' do
        expect(reader.project.end_date).to eq(project_json['end'])
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

  context 'when rda_json is missing expected keys' do
    let(:reader) { described_class.new(rda_json: {}) }

    it 'returns nil for scalar accessors' do
      expect(reader.title).to be_nil
      expect(reader.dmp_id.identifier).to be_nil
      expect(reader.dmp_id.type).to be_nil
      expect(reader.project.start_date).to be_nil
      expect(reader.project.end_date).to be_nil
    end
  end

  context 'when rda_json is nil' do
    let(:reader) { described_class.new(rda_json: nil) }

    it 'does not raise and returns nil/empty defaults' do
      expect(reader.dmp_id.identifier).to be_nil
    end
  end
end
