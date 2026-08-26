# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::CommonMadmp::ContentNegotiation do
  let(:vendor_type) { 'application/vnd.org.rd-alliance.dmp-common.v1.2+json' }

  let(:dummy_class) do
    Class.new(ActionController::Base) do
      include Api::CommonMadmp::ContentNegotiation

      def request
        @request ||= ActionDispatch::TestRequest.create
      end

      def not_acceptable_error
        @negotiated_content_type = nil
      end
    end
  end

  describe '#ranked_acceptable_types' do
    it 'selects the type with the highest client preference' do
      instance = dummy_class.new
      instance.request.headers['Accept'] = "application/json;q=0.5, #{vendor_type};q=1.0"

      expect(instance.send(:ranked_acceptable_types, instance.request.headers['Accept']))
        .to eq([vendor_type, 'application/json'])
    end

    it 'selects JSON when it has the highest client preference' do
      instance = dummy_class.new
      instance.request.headers['Accept'] = "application/json;q=1.0, #{vendor_type};q=0.5"

      expect(instance.send(:ranked_acceptable_types, instance.request.headers['Accept']))
        .to eq(['application/json', vendor_type])
    end

    it 'preserves header order when q-values are tied' do
      instance = dummy_class.new
      instance.request.headers['Accept'] = "#{vendor_type};q=0.8, application/json;q=0.8"

      expect(instance.send(:ranked_acceptable_types, instance.request.headers['Accept']))
        .to eq([vendor_type, 'application/json'])
    end

    it 'drops q=0 media types before negotiating' do
      instance = dummy_class.new
      instance.request.headers['Accept'] = "application/json;q=0, #{vendor_type};q=0.5"

      expect(instance.send(:ranked_acceptable_types, instance.request.headers['Accept']))
        .to eq([vendor_type])
    end

    it 'returns an empty list when the only type is excluded with q=0' do
      instance = dummy_class.new
      instance.request.headers['Accept'] = 'application/json;q=0'

      expect(instance.send(:ranked_acceptable_types, instance.request.headers['Accept'])).to eq([])
    end

    it 'ignores unsupported media types when a supported type is also present' do
      instance = dummy_class.new
      instance.request.headers['Accept'] = "application/xml, #{vendor_type}"

      expect(instance.send(:ranked_acceptable_types, instance.request.headers['Accept']))
        .to eq(['application/xml', vendor_type])
    end
  end

  describe '#negotiated_content_type_for' do
    it 'chooses the vendor media type when it is the highest-preference match' do
      instance = dummy_class.new
      instance.request.headers['Accept'] = "application/json;q=0.5, #{vendor_type};q=1.0"

      result = instance.send(:negotiated_content_type_for, instance.request.headers['Accept'])

      expect(result).to eq(vendor_type)
    end

    it 'chooses JSON when it is the highest-preference match' do
      instance = dummy_class.new
      instance.request.headers['Accept'] = "application/json;q=1.0, #{vendor_type};q=0.5"

      result = instance.send(:negotiated_content_type_for, instance.request.headers['Accept'])

      expect(result).to eq('application/json')
    end

    it 'falls back to JSON for a bare wildcard' do
      instance = dummy_class.new
      instance.request.headers['Accept'] = '*/*'

      result = instance.send(:negotiated_content_type_for, instance.request.headers['Accept'])

      expect(result).to eq('application/json')
    end

    it 'falls back to JSON for an application wildcard' do
      instance = dummy_class.new
      instance.request.headers['Accept'] = 'application/*'

      result = instance.send(:negotiated_content_type_for, instance.request.headers['Accept'])

      expect(result).to eq('application/json')
    end

    it 'returns nil when no supported type is present' do
      instance = dummy_class.new
      instance.request.headers['Accept'] = 'application/xml'

      result = instance.send(:negotiated_content_type_for, instance.request.headers['Accept'])

      expect(result).to be_nil
    end

    it 'returns nil when the only match is excluded with q=0' do
      instance = dummy_class.new
      instance.request.headers['Accept'] = 'application/json;q=0'

      result = instance.send(:negotiated_content_type_for, instance.request.headers['Accept'])

      expect(result).to be_nil
    end

    it 'returns nil when a supported concrete type is excluded with q=0 under an application wildcard' do
      instance = dummy_class.new
      instance.request.headers['Accept'] = 'application/*;q=0.5, application/json;q=0'

      result = instance.send(:negotiated_content_type_for, instance.request.headers['Accept'])

      expect(result).to be_nil
    end

    it 'returns nil when a wildcard match is excluded with q=0 alongside a lower-priority supported type' do
      instance = dummy_class.new
      instance.request.headers['Accept'] = '*/*;q=0.5, application/json;q=0'

      result = instance.send(:negotiated_content_type_for, instance.request.headers['Accept'])

      expect(result).to be_nil
    end
  end

  describe '#negotiate_dmp_format' do
    it 'sets @negotiated_content_type when a supported type is found' do
      instance = dummy_class.new
      instance.request.headers['Accept'] = "application/json;q=0.5, #{vendor_type};q=1.0"

      instance.send(:negotiate_dmp_format)

      expect(instance.instance_variable_get(:@negotiated_content_type)).to eq(vendor_type)
    end

    it 'clears @negotiated_content_type and triggers not_acceptable_error when nothing matches' do
      instance = dummy_class.new
      instance.request.headers['Accept'] = 'application/xml'

      instance.send(:negotiate_dmp_format)

      expect(instance.instance_variable_get(:@negotiated_content_type)).to be_nil
    end
  end
end
