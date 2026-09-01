# frozen_string_literal: true

module Api
  module CommonMadmp
    # Concern that conforms to pagination requirements as specified in the Common MaDMP API spec
    module Pagination
      extend ActiveSupport::Concern

      private

      # retrieve the requested pagination params or use defaults
      # only allow 100 per page as the max
      def pagination_params
        max_per_page = Rails.configuration.x.application.api_max_page_size
        @offset = params.fetch('offset', 1).to_i
        @count = params.fetch('count', max_per_page).to_i
        @count = max_per_page if @count > max_per_page
      end

      def paginate_response(results:)
        results = results.page(@offset).per(@count)
        @total_items = results.total_count
        results
      end
    end
  end
end
