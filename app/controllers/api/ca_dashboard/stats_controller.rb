# frozen_string_literal: true

module Api
  module CaDashboard
    # Handles CRUD operations for "/api/ca_dashboard/stats"
    class StatsController < Api::V1::BaseApiController
      # Allow public access / bypass JWT authentication via "POST /api/v1/authenticate"
      skip_before_action :authorize_request, only: [:index]

      # GET /api/ca_dashboard/stats
      def index
        base_hash = {
          'plans' => Plan.all,
          'orgs' => Org.where(managed: true).all,
          'users' => User.all
        }
        @totals = {
          'all_time' => all_time_counts(base_hash),
          'last_30_days' => last_30_days_counts(base_hash)
        }
        begin
          @totals['custom_range'] = custom_range_counts(base_hash) if date_params_present?
          render 'api/ca_dashboard/stats/index', status: :ok
        rescue ArgumentError
          error_msg = _('Invalid date format. please use YYYY-MM-DD when supplying `start` or `end` params.')
          render_error(errors: [error_msg], status: :bad_request)
        end
      end

      private

      def all_time_counts(base_hash)
        base_hash.transform_values(&:count)
      end

      def last_30_days_counts(base_hash)
        base_hash.transform_values do |scope|
          scope.where('created_at >= ?', 30.days.ago).count
        end
      end

      def custom_range_counts(base_hash)
        start_date = parse_date(params[:start])
        end_date = parse_date(params[:end])
        base_hash.transform_values do |scope|
          scope.where(created_at: start_date..end_date).count
        end
      end

      def date_params_present?
        params[:start].present? || params[:end].present?
      end

      def parse_date(date_string)
        Date.strptime(date_string, '%Y-%m-%d') if date_string.present?
      end
    end
  end
end
