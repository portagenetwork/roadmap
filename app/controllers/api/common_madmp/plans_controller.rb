# frozen_string_literal: true

module Api
  module CommonMadmp
    # Controller for the RDA Common MADMP API.
    class PlansController < BaseApiController
      include Api::CommonMadmp::Sorting

      before_action :negotiate_dmp_format
      after_action :apply_negotiated_content_type

      POLICY = Api::V2::PlansPolicy
      JSON_CONTENT_TYPE = Mime[:json].to_s
      RDA_DMP_CONTENT_TYPE = Mime[:rda_dmp_v12].to_s

      # GET /dmps/:id
      def show
        @plan = plans_scope.find_by(id: params[:id])

        return dmp_not_found_error unless plans_policy(@plan).show?

        response.headers['Last-Modified'] = @plan.updated_at.httpdate

        render '/api/common_madmp/dmps/show', status: :ok
      end

      # GET /dmps
      def index
        @plans = plans_scope
        @plans = apply_sorting(@plans)
        return if performed?

        @items = paginate_response(results: @plans)
        render '/api/common_madmp/dmps/index', status: :ok
      end

      private

      def negotiate_dmp_format
        # See the "Schema extension" section of the RDA Common MADMP API specification:
        # https://github.com/RDA-DMP-Common/common-madmp-api/blob/init/openapi.yaml
        ordered_accept_types(request.headers['Accept']).each do |type|
          case type

          # No `Accept` header, or a wildcard/unqualified `application/json` request.
          # (Rails treats a missing `Accept` header as `*/*`)
          when '*/*', 'application/*', JSON_CONTENT_TYPE
            @negotiated_content_type = JSON_CONTENT_TYPE

          when RDA_DMP_CONTENT_TYPE
            @negotiated_content_type = RDA_DMP_CONTENT_TYPE
          end

          break if @negotiated_content_type.present?
        end

        not_acceptable_error unless @negotiated_content_type.present?
      end

      # NOTE: Hand-rolled with Rack::Utils.q_values instead of Rails' own Accept
      # negotiation (request.accepts / request.formats / request.negotiate_mime).
      # All three rely on Mime::Type.parse, which mis-parses q-values with a
      # non-zero integer part (e.g. "q=1.0" becomes 0.0) -- confirmed directly
      # against Rails 6.2. Fixed upstream in rails/rails#51594 (merged April
      # 2024); once we're on a Rails version with that fix, this helper and its
      # caller can likely be replaced with request.negotiate_mime.
      #
      # Types with an explicit q=0 are excluded, per RFC 9110 ("not acceptable").
      # Ties preserve original header order.
      def ordered_accept_types(header)
        header = header.presence || '*/*'

        Rack::Utils.q_values(header)
                   .each_with_index
                   # Sort by descending q-value; original index preserves header order for ties.
                   .sort_by { |(_type, q), index| [-q, index] }
                   .reject { |(_type, q), _index| q.zero? }
                   .map { |(type, _q), _index| type }
      end

      def apply_negotiated_content_type
        return unless @negotiated_content_type.present?

        response.headers['Content-Type'] = @negotiated_content_type
      end

      def plans_scope
        POLICY::Scope.new(@resource_owner).resolve
      end

      def plans_policy(plan)
        POLICY.new(@resource_owner, plan)
      end

      def dmp_not_found_error
        render_error(
          error_code: 'dmp_not_found',
          error_message: _('Plan not found'),
          status: :not_found
        )
      end

      def not_acceptable_error
        render_error(
          error_code: 'not_acceptable',
          error_message: _('Unsupported schema version requested'),
          status: :not_acceptable
        )
      end
    end
  end
end
