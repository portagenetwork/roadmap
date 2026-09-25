# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::CommonMadmp::Pagination do
  let(:dummy_class) do
    Class.new do
      include Api::CommonMadmp::Pagination

      attr_reader :last_error_message, :params

      def initialize(params = {})
        @params = ActionController::Parameters.new(params)
      end

      # Mirrors real controller behavior: once an error has been
      # rendered, the request is "performed" and downstream code
      # (pagination_params) should stop.
      def performed?
        @last_error_message.present?
      end

      # Fakes ActionController's render: records the message instead of
      # rendering, so performed? can flip true the way it would
      # after a real render call.
      def invalid_query_string_error(error_message:)
        @last_error_message = error_message
      end
    end
  end

  let(:params) { {} }
  let(:instance) { dummy_class.new(params) }

  describe '#pagination_params' do
    context 'when no pagination params are supplied' do
      it 'uses the default offset and count' do
        instance.send(:pagination_params)

        expect(instance.instance_variable_get(:@offset)).to eq(described_class::DEFAULT_OFFSET)
        expect(instance.instance_variable_get(:@count)).to eq(described_class::DEFAULT_COUNT)
      end
    end

    context 'with valid offset and count values' do
      let(:params) { { offset: '15', count: '7' } }

      it 'parses them into integers' do
        instance.send(:pagination_params)

        expect(instance.last_error_message).to be_nil
        expect(instance.instance_variable_get(:@offset)).to eq(15)
        expect(instance.instance_variable_get(:@count)).to eq(7)
      end
    end

    context 'with a malformed integer value' do
      let(:params) { { offset: 'abc' } }

      it 'rejects it with the invalid query string error' do
        instance.send(:pagination_params)

        expect(instance.last_error_message).to eq('The query string contained invalid pagination parameters.')
      end
    end

    context 'when the configured max page size is overridden' do
      it 'clamps the default and max count to the configured value' do
        original = Rails.configuration.x.application.api_max_page_size
        Rails.configuration.x.application.api_max_page_size = 12

        begin
          expect(instance.send(:default_count)).to eq(12)
          expect(instance.send(:max_count)).to eq(12)
        ensure
          Rails.configuration.x.application.api_max_page_size = original
        end
      end
    end
  end

  describe '#valid_pagination_params?' do
    context 'with a negative offset and a non-positive count' do
      it 'is invalid' do
        instance.instance_variable_set(:@offset, -1)
        instance.instance_variable_set(:@count, 0)

        expect(instance.send(:valid_pagination_params?)).to be(false)
      end
    end

    context 'with a count above the maximum allowed value' do
      it 'is invalid' do
        instance.instance_variable_set(:@offset, 0)
        instance.instance_variable_set(:@count, described_class::MAX_COUNT + 1)

        expect(instance.send(:valid_pagination_params?)).to be(false)
      end
    end
  end
end
