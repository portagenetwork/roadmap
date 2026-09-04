# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::CommonMadmp::Filtering do
  let(:dummy_class) do
    Class.new do
      include Api::CommonMadmp::Filtering

      attr_accessor :params, :errors

      def initialize(params = {})
        @params = ActionController::Parameters.new(params)
        @errors = []
      end

      def performed?
        @errors.present?
      end

      def invalid_query_string_error(error_message:)
        @errors << error_message
      end
    end
  end

  let(:fake_scope_class) do
    Class.new do
      attr_reader :where_calls, :join_calls

      def initialize
        @where_calls = []
        @join_calls = []
      end

      def where(*args)
        @where_calls << args
        self
      end

      def left_joins(*args)
        @join_calls << args
        self
      end
    end
  end

  let(:params) { {} }
  let(:instance) { dummy_class.new(params) }
  let(:scope) { fake_scope_class.new }

  describe '#apply_filters' do
    context 'when no supported filters are given' do
      it 'returns the scope unchanged' do
        result = instance.send(:apply_filters, scope)

        expect(result).to eq(scope)
        expect(scope.where_calls).to be_empty
      end
    end

    context 'with a supported text filter' do
      let(:params) { { title: 'Alpha' } }

      it 'applies a lowercased, wildcard-wrapped LIKE condition' do
        result = instance.send(:apply_filters, scope)

        expect(scope.where_calls).to include(['LOWER(plans.title) LIKE ?', '%alpha%'])
        expect(result).to eq(scope)
      end
    end

    context 'with a title value containing leading/trailing whitespace and mixed case' do
      let(:params) { { title: '  Alpha  ' } }

      it 'strips whitespace and downcases before building the LIKE pattern' do
        instance.send(:apply_filters, scope)

        expect(scope.where_calls).to include(['LOWER(plans.title) LIKE ?', '%alpha%'])
      end
    end

    context 'with a title value containing LIKE metacharacters' do
      let(:params) { { title: '50%_off' } }

      it 'escapes % and _ so they are matched literally' do
        instance.send(:apply_filters, scope)

        expect(scope.where_calls).to include(['LOWER(plans.title) LIKE ?', '%50\%\_off%'])
      end
    end

    context 'with supported date filters' do
      let(:params) { { created_after: '2024-01-01', modified_before: '2024-02-15' } }

      it 'casts date params and adds ranged conditions with day boundaries' do
        instance.send(:apply_filters, scope)

        expect(scope.where_calls).to include(
          ['plans.created_at >= ?', Date.parse('2024-01-01').beginning_of_day]
        )
        expect(scope.where_calls).to include(
          ['plans.updated_at <= ?', Date.parse('2024-02-15').end_of_day]
        )
      end
    end

    context 'with all four date filter keys' do
      let(:params) do
        {
          created_after: '2024-01-01',
          created_before: '2024-01-31',
          modified_after: '2024-02-01',
          modified_before: '2024-02-28'
        }
      end

      it 'maps each key to the correct column and bound' do
        instance.send(:apply_filters, scope)

        expect(scope.where_calls).to include(
          ['plans.created_at >= ?', Date.parse('2024-01-01').beginning_of_day],
          ['plans.created_at <= ?', Date.parse('2024-01-31').end_of_day],
          ['plans.updated_at >= ?', Date.parse('2024-02-01').beginning_of_day],
          ['plans.updated_at <= ?', Date.parse('2024-02-28').end_of_day]
        )
      end
    end

    context 'with an unparseable date value' do
      let(:params) { { created_after: 'not-a-date' } }

      it 'records an invalid query string error and applies no filter' do
        result = instance.send(:apply_filters, scope)

        expect(instance.errors).to eq(['The query string contained invalid filter parameters.'])
        expect(scope.where_calls).to be_empty
        expect(result).to eq(scope)
      end
    end

    context 'when a date error occurs before a later supported filter' do
      # created_after precedes created_before in ALLOWED_FILTER_KEYS, and permit
      # yields keys in that declaration order (not input order), so created_after
      # is guaranteed to be processed first here.
      let(:params) { { created_after: 'not-a-date', created_before: '2024-01-31' } }

      it 'stops processing once performed? becomes true, skipping subsequent filters' do
        instance.send(:apply_filters, scope)

        expect(instance.errors).to eq(['The query string contained invalid filter parameters.'])
        expect(scope.where_calls).to be_empty
        expect(scope.where_calls.map(&:first)).not_to include('plans.created_at <= ?')
      end
    end

    context 'with blank filter values' do
      let(:params) { { title: '', created_after: nil } }

      it 'drops blank values before they reach apply_filter' do
        result = instance.send(:apply_filters, scope)

        expect(scope.where_calls).to be_empty
        expect(instance.errors).to be_empty
        expect(result).to eq(scope)
      end
    end

    context 'with a whitespace-only title value' do
      let(:params) { { title: '   ' } }

      it 'treats it as blank and applies no filter' do
        result = instance.send(:apply_filters, scope)

        expect(scope.where_calls).to be_empty
        expect(instance.errors).to be_empty
        expect(result).to eq(scope)
      end
    end

    context 'with an unsupported filter key' do
      let(:params) { { foo: 'bar' } }

      it 'ignores the key, applies no filter, and records no error' do
        result = instance.send(:apply_filters, scope)

        expect(instance.errors).to be_empty
        expect(scope.where_calls).to be_empty
        expect(result).to eq(scope)
      end
    end

    context 'when the instance was already performed before filtering starts' do
      let(:params) { { title: 'Alpha', created_after: '2024-01-01' } }

      it 'still applies the first filter, then stops after it flips performed? again' do
        instance.send(:invalid_query_string_error, error_message: 'previous error')

        result = instance.send(:apply_filters, scope)

        # performed? is already true going in, but apply_filters only checks
        # performed? *after* each iteration, so the first supported filter in
        # allow-list order (title, since it precedes created_after in
        # ALLOWED_FILTER_KEYS) is still applied before the loop returns early.
        expect(scope.where_calls).to include(['LOWER(plans.title) LIKE ?', '%alpha%'])
        expect(scope.where_calls.map(&:first)).not_to include('plans.created_at >= ?')
        expect(result).to eq(scope)
      end
    end
  end
end
