# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::CommonMadmp::Sorting do
  let(:dummy_class) do
    Class.new do
      include Api::CommonMadmp::Sorting

      attr_accessor :params, :errors

      def initialize(params = {})
        @params = params
        @errors = []
      end

      # Mirrors real controller behavior: once an error has been
      # rendered, the request is "performed" and downstream code
      # (apply_sorting) should stop.
      def performed?
        @errors.present?
      end

      # Fakes ActionController's render: records the message instead of
      # rendering, so performed? can flip true the way it would
      # after a real render call.
      def invalid_query_string_error(error_message:)
        @errors << error_message
      end
    end
  end

  # Minimal stand-in for an ActiveRecord::Relation. Records every
  # `.order(...)` call it receives (in order) and returns itself so
  # calls can be chained, the same way a real relation would.
  let(:fake_scope_class) do
    Class.new do
      attr_reader :order_calls

      def initialize
        @order_calls = []
      end

      def order(criteria)
        @order_calls << criteria
        self
      end
    end
  end

  let(:params) { {} }
  let(:instance) { dummy_class.new(params) }
  let(:scope) { fake_scope_class.new }

  describe '#apply_sorting' do
    context 'when no sort param is given' do
      it 'applies the default sort (created desc)' do
        instance.send(:apply_sorting, scope)

        expect(scope.order_calls).to eq([{ 'created_at' => :desc }])
      end
    end

    context 'with a single valid sort param' do
      let(:params) { { sort: ['title,asc'] } }

      it 'maps the field to its column and applies order' do
        instance.send(:apply_sorting, scope)

        expect(scope.order_calls).to eq([{ 'title' => :asc }])
      end
    end

    context 'with multiple valid sort params' do
      let(:params) { { sort: ['title,asc', 'created,desc'] } }

      it 'chains order calls for each field, in order' do
        result = instance.send(:apply_sorting, scope)

        expect(scope.order_calls).to eq([{ 'title' => :asc }, { 'created_at' => :desc }])
        expect(result).to eq(scope)
      end
    end

    context 'with an unsupported field' do
      let(:params) { { sort: ['bogus,asc'] } }

      it 'does not order the scope and records an error' do
        result = instance.send(:apply_sorting, scope)

        expect(scope.order_calls).to be_empty
        expect(result).to eq(scope)
        expect(instance.errors).to include('The query string contained invalid sort parameters.')
      end
    end

    context 'with an unsupported direction' do
      let(:params) { { sort: ['title,sideways'] } }

      it 'does not order the scope and marks the request as performed' do
        instance.send(:apply_sorting, scope)

        expect(scope.order_calls).to be_empty
        expect(instance.performed?).to be(true)
      end
    end

    context 'with a mix of valid and invalid sort params' do
      let(:params) { { sort: ['title,asc', 'bogus,desc'] } }

      it 'aborts entirely and applies no ordering' do
        instance.send(:apply_sorting, scope)

        expect(scope.order_calls).to be_empty
        expect(instance.errors.size).to eq(1)
      end
    end

    context 'when the request was already performed (e.g. an earlier error response)' do
      let(:params) { { sort: ['title,asc'] } }

      it 'returns the scope untouched' do
        instance.send(:invalid_query_string_error, error_message: 'previous error')
        result = instance.send(:apply_sorting, scope)

        expect(scope.order_calls).to be_empty
        expect(result).to eq(scope)
      end
    end
  end

  describe '#parse_sort_params' do
    context 'when sort is blank' do
      let(:params) { { sort: [] } }

      it 'falls back to the default sort' do
        expect(instance.send(:parse_sort_params)).to eq([['created_at', :desc]])
      end
    end

    context 'with surrounding whitespace and mixed case direction' do
      let(:params) { { sort: [' title , ASC '] } }

      it 'strips whitespace and downcases the direction' do
        expect(instance.send(:parse_sort_params)).to eq([['title', :asc]])
      end
    end

    context 'with an invalid field' do
      let(:params) { { sort: ['nope,asc'] } }

      it 'returns nil' do
        expect(instance.send(:parse_sort_params)).to be_nil
      end
    end
  end
end
