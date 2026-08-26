# frozen_string_literal: true

module Api
  module CommonMadmp
    # Negotiates the response media type for Common MADMP API requests.
    # - This intentionally supports only standard JSON and the vendor-specific DMP Common v1.2 media type.
    module ContentNegotiation
      extend ActiveSupport::Concern

      JSON_CONTENT_TYPE = Mime[:json].to_s
      RDA_DMP_CONTENT_TYPE = Mime[:rda_dmp_v12].to_s
      SUPPORTED_TYPES = [RDA_DMP_CONTENT_TYPE, JSON_CONTENT_TYPE].freeze
      # Wildcards are valid fallback matches, but they must not override a concrete
      # supported subtype when that subtype is explicitly excluded with q=0.
      WILDCARD_TYPES = ['*/*', 'application/*'].freeze

      included do
        prepend_before_action :negotiate_dmp_format
        after_action :apply_negotiated_content_type
      end

      private

      def negotiate_dmp_format
        # Reuse the negotiated type when the client accepts a supported JSON
        # representation; otherwise raise the standard 406 with the API-specific
        # error handler.
        @negotiated_content_type = negotiated_content_type_for(request.headers['Accept'])
        not_acceptable_error unless @negotiated_content_type.present?
      end

      def negotiated_content_type_for(header)
        # Keep the overall flow simple: rank the client’s acceptable types,
        # then return the first supported match in order of preference.
        ranked_acceptable_types(header).each do |type|
          return RDA_DMP_CONTENT_TYPE if type == RDA_DMP_CONTENT_TYPE
          return JSON_CONTENT_TYPE if type == JSON_CONTENT_TYPE || WILDCARD_TYPES.include?(type)
        end

        nil
      end

      def ranked_acceptable_types(header)
        # Hand-rolled with Rack::Utils.q_values instead of Rails' own Accept
        # negotiation (request.accepts / request.formats / request.negotiate_mime).
        # All three rely on Mime::Type.parse, which mis-parses q-values with a
        # non-zero integer part (e.g. "q=1.0" becomes 0.0) -- confirmed directly
        # against Rails 6.2. Fixed upstream in rails/rails#51594 (merged April
        # 2024); once we're on a Rails version with that fix, this helper and its
        # caller can likely be replaced with request.negotiate_mime.
        entries = Rack::Utils.q_values(header.presence || '*/*').each_with_index.to_a

        entries
          # Ignore explicitly unacceptable formats before we rank the rest.
          .select { |(_type, q), _idx| q.positive? }
          # Wildcards are fallbacks only; a q=0 concrete subtype must still block
          # them from satisfying that concrete type.
          .reject { |(type, _q), _idx| wildcard_suppressed_by_q_zero?(type, entries) }
          # Sort by descending q-value; original index preserves header order for ties
          .sort_by { |(_type, q), idx| [-q, idx] }
          .map { |(type, _q), _idx| type }
      end

      def wildcard_suppressed_by_q_zero?(type, entries)
        # A wildcard is only a fallback. If the concrete subtype it would match
        # was explicitly rejected with q=0, do not allow the wildcard to revive it.
        return false unless WILDCARD_TYPES.include?(type)

        entries.any? do |(candidate, q), _idx|
          q.zero? && concrete_type_matches_wildcard?(candidate, type)
        end
      end

      def concrete_type_matches_wildcard?(candidate, wildcard)
        return false unless SUPPORTED_TYPES.include?(candidate)

        case wildcard
        when '*/*'
          true
        when 'application/*'
          candidate.start_with?('application/')
        else
          false
        end
      end

      def apply_negotiated_content_type
        # Ensure the response content type matches the negotiated type, defaulting
        # to JSON when no explicit negotiation was required.
        response.headers['Content-Type'] = @negotiated_content_type || JSON_CONTENT_TYPE
      end
    end
  end
end
