# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TemplateTranslationService do
  before do
    @funding_org = create(:org, :funder)
    @original_default_funder_id = Rails.application.config.default_funder_id
    Rails.application.config.default_funder_id = @funding_org.id

    @default_template = create(:template, :default, :published, org: @funding_org)
    @custom_template  = create(:template, :published, org: create(:org))

    # Safely intercept  translations
    def TemplateTranslationService._(val)
      "translated_#{val}"
    end
  end

  after do
    Rails.application.config.default_funder_id = @original_default_funder_id
  end

  describe '.translate' do
    it 'returns nil if the passed record is blank' do
      expect(described_class.translate(nil, :title)).to be_nil
    end

    it 'returns the raw value if the attribute content is blank' do
      @default_template.title = ''
      expect(described_class.translate(@default_template, :title)).to eq('')
    end

    context 'when the record belongs to the default funder' do
      it 'translates the attribute for a Template record' do
        @default_template.title = 'Default Title'

        expect(described_class.translate(@default_template, :title)).to eq('translated_Default Title')
      end

      it 'translates the attribute for an associated child record (e.g., Phase)' do
        phase = create(:phase, template: @default_template, title: 'Default Phase')

        expect(described_class.translate(phase, :title)).to eq('translated_Default Phase')
      end
    end

    context 'when the record belongs to a customized template' do
      it 'returns the exact database string untouched' do
        @custom_template.title = 'Custom Org Title'

        expect(described_class.translate(@custom_template, :title)).to eq('Custom Org Title')
      end
    end
  end

  describe 'private methods' do
    describe '#default_funder_template?' do
      it 'returns false when passed a record lacking a template' do
        orphan_phase = build(:phase, template: nil)

        expect(described_class.send(:default_funder_template?, orphan_phase)).to be false
      end
    end
  end
end
