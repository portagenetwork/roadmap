# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V2::PlanPresenter do
  let!(:plan) { create(:plan, :creator) }

  describe '#initialize(plan:, complete:)' do
    it 'includes only answered questions in complete_plan_data' do
      answered = create(:answer, plan: plan, text: 'A non-blank answer')
      unanswered = create(:answer, plan: plan, text: '')

      presenter = described_class.new(plan: plan, complete: true)

      ids = presenter.complete_plan_data.pluck(:id)
      expect(ids).to include(answered.question_id)
      expect(ids).not_to include(unanswered.question_id)
    end
  end

  describe '#identifier' do
    context 'when the plan has a canonical DMP DOI identifier' do
      let(:datacite_scheme) { create(:identifier_scheme, name: 'datacite') }
      let!(:doi_identifier) do
        create(:identifier, identifiable: plan, identifier_scheme: datacite_scheme, value: '10.83996/1234')
      end

      it 'returns the canonical plan identifier' do
        presenter = described_class.new(plan: plan)

        expect(presenter.identifier).to eq(doi_identifier)
      end
    end

    context 'when the plan has no DMP DOI identifier' do
      it 'returns a new Identifier with the API v2 plan URL' do
        presenter = described_class.new(plan: plan)
        expected_url = Rails.application.routes.url_helpers.api_v2_plan_url(plan)

        expect(presenter.identifier.value).to eq(expected_url)
      end
    end
  end
end
