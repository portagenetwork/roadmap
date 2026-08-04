# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V2::PlanSnapshotPresenter do
  describe '#template' do
    let(:plan) { create(:plan, :creator) }
    let(:presenter) { described_class.new(plan: plan) }

    it 'returns the template id, title, and version' do
      template = presenter.template

      expect(template[:id]).to eq(plan.template.id)
      expect(template[:title]).to eq(plan.template.title)
      expect(template[:version]).to eq(plan.template.version)
    end

    context 'when the template has no phases' do
      it 'returns an empty phases array' do
        expect(presenter.template[:phases]).to eq([])
      end
    end

    context 'when the template has a phase' do
      let(:phase) { create(:phase, template: plan.template, title: 'Phase 1', number: 1) }

      before { phase }

      it 'renders the phase title and number' do
        rendered_phase = presenter.template[:phases].first

        expect(rendered_phase[:title]).to eq('Phase 1')
        expect(rendered_phase[:number]).to eq(1)
      end

      it 'renders an empty sections array when the phase has no sections' do
        expect(presenter.template[:phases].first[:sections]).to eq([])
      end
    end

    context 'when a phase has a section' do
      let(:phase) { create(:phase, template: plan.template) }
      let(:section) { create(:section, phase: phase, title: 'Section 1', number: 1, modifiable: true) }

      before { section }

      it 'renders the section title, number, and modifiable' do
        rendered_section = presenter.template[:phases].first[:sections].first

        expect(rendered_section[:title]).to eq('Section 1')
        expect(rendered_section[:number]).to eq(1)
        expect(rendered_section[:modifiable]).to be(true)
      end

      it 'renders an empty questions array when the section has no questions' do
        expect(presenter.template[:phases].first[:sections].first[:questions]).to eq([])
      end
    end

    context 'when a section has a question' do
      let(:phase) { create(:phase, template: plan.template) }
      let(:section) { create(:section, phase: phase) }
      let(:question) { create(:question, section: section, number: 1, text: 'What is your plan?') }

      before { question }

      it 'renders the question id, number, and text' do
        rendered_question = presenter.template[:phases].first[:sections].first[:questions].first

        expect(rendered_question[:id]).to eq(question.id)
        expect(rendered_question[:number]).to eq(1)
        expect(rendered_question[:text]).to eq('What is your plan?')
      end

      it 'stringifies a nil question text' do
        question.update_column(:text, nil)
        rendered_question = presenter.template[:phases].first[:sections].first[:questions].first

        expect(rendered_question[:text]).to eq('')
      end

      context 'when the question has a format' do
        let(:question) do
          create(:question, section: section, question_format: create(:question_format, title: 'Text area'))
        end

        it 'renders the format id and title' do
          rendered_question = presenter.template[:phases].first[:sections].first[:questions].first

          expect(rendered_question[:format][:id]).to eq(question.question_format.id)
          expect(rendered_question[:format][:title]).to eq('Text area')
        end
      end

      context 'when the question has no format' do
        let(:question) { create(:question, section: section) }

        before { question.update_column(:question_format_id, nil) }

        it 'sets format to nil' do
          rendered_question = presenter.template[:phases].first[:sections].first[:questions].first

          expect(rendered_question[:format]).to be_nil
        end
      end

      context 'when the plan has an answer for the question' do
        before { create(:answer, plan: plan, question: question, text: 'Test answer') }

        it 'renders the answer text' do
          rendered_question = presenter.template[:phases].first[:sections].first[:questions].first

          expect(rendered_question[:answer][:text]).to eq('Test answer')
        end
      end

      context 'when the plan has no answer for the question' do
        it 'renders an answer hash with an empty string for text' do
          rendered_question = presenter.template[:phases].first[:sections].first[:questions].first

          expect(rendered_question[:answer]).to eq(text: '')
        end
      end

      context 'when the plan has answers for other questions but not this one' do
        let(:other_question) { create(:question, section: section, number: 2) }

        before { create(:answer, plan: plan, question: other_question, text: 'Other answer') }

        it 'does not leak the other answer onto this question' do
          rendered_question = presenter.template[:phases].first[:sections].first[:questions]
                                       .find { |q| q[:id] == question.id }

          expect(rendered_question[:answer]).to eq(text: '')
        end
      end
    end
  end
end
