# frozen_string_literal: true

require 'rails_helper'

describe 'api/v2/plans/_extension.json.jbuilder' do
  before do
    @plan = create(:plan, :creator)
    @plan.template.update!(title: 'Template title')
    @presenter = Api::V2::PlanPresenter.new(plan: @plan)
  end

  describe 'extension payload' do
    before do
      render partial: 'api/v2/plans/extension',
             locals: { plan: @plan, presenter: @presenter }
      @json = JSON.parse(rendered).with_indifferent_access
      @extension = @json[:extension].first.with_indifferent_access
    end

    it 'includes one extension entry' do
      expect(@json[:extension].length).to eql(1)
    end

    it 'includes the dmproadmap template id' do
      expect(@extension[:dmproadmap][:template][:id]).to eql(@plan.template.id)
    end

    it 'includes template title' do
      expect(@extension[:dmproadmap][:template][:title]).to eql('Template title')
    end

    it 'does not include complete_plan by default' do
      expect(@extension[:complete_plan]).to be_nil
    end
  end

  describe 'when @complete is true' do
    before do
      assign(:complete, true)
    end

    it 'includes complete_plan when presenter has data' do
      @presenter.stubs(:complete_plan_data).returns([
                                                      {
                                                        id: 123,
                                                        title: 'Q1',
                                                        section: 'Section A',
                                                        question: 'What data?',
                                                        answer: 'Public repository'
                                                      }
                                                    ])

      render partial: 'api/v2/plans/extension',
             locals: { plan: @plan, presenter: @presenter }

      json = JSON.parse(rendered).with_indifferent_access
      extension = json[:extension].first.with_indifferent_access

      expect(extension[:complete_plan]).to be_an(Array)
      expect(extension[:complete_plan].length).to eql(1)
      expect(extension[:complete_plan].first[:question_id]).to eql(123)
      expect(extension[:complete_plan].first[:title]).to eql('Q1')
      expect(extension[:complete_plan].first[:section]).to eql('Section A')
      expect(extension[:complete_plan].first[:question]).to eql('What data?')
      expect(extension[:complete_plan].first[:answer]).to eql('Public repository')
    end

    it 'omits complete_plan when presenter data is blank' do
      @presenter.stubs(:complete_plan_data).returns([])

      render partial: 'api/v2/plans/extension',
             locals: { plan: @plan, presenter: @presenter }

      json = JSON.parse(rendered).with_indifferent_access
      extension = json[:extension].first.with_indifferent_access

      expect(extension[:complete_plan]).to be_nil
    end
  end
end
