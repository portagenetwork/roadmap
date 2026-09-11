# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::CommonMadmp::QueryFiltering do
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

      def distinct
        self
      end
    end
  end

  let(:params) { {} }
  let(:instance) { dummy_class.new(params) }
  let(:scope) { fake_scope_class.new }

  describe '#query_filter' do
    context 'with a query search across human-readable fields' do
      let(:params) { { query: %w[climate biodiversity] } }

      it 'matches the plan and dataset title/description fields case-insensitively' do
        instance.send(:apply_filters, scope)

        expect(scope.where_calls).not_to be_empty
        expect(scope.where_calls.last.first).to include('LOWER(plans.title) LIKE ?')
        expect(scope.where_calls.last.first).to include('LOWER(research_outputs.description) LIKE ?')
      end
    end
  end
end
