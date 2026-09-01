# frozen_string_literal: true

module Api
  module CommonMadmp
    # Helper class for generic API V2 pagination
    class PaginationPresenter
      def initialize(current_url:, count:, total_items:, current_page: 1)
        @url = current_url
        @count = count
        @total_items = total_items
        @offset = current_page
      end

      def url_without_pagination
        return nil unless @url.present? && @url.is_a?(String)

        url = @url.gsub(/count=\d+/, '')
                  .gsub(/offset=\d+/, '')
                  .gsub(/(&)+$/, '').gsub(/\?$/, '')

        (url.include?('?') ? "#{url}&" : "#{url}?")
      end

      def prev_page?
        total_pages > 1 && @offset != 1
      end

      def next_page?
        total_pages > 1 && @offset < total_pages
      end

      def prev_page_link
        "#{url_without_pagination}offset=#{@offset - 1}&count=#{@count}"
      end

      def next_page_link
        "#{url_without_pagination}offset=#{@offset + 1}&count=#{@count}"
      end

      private

      def total_pages
        return 1 unless @total_items.present? && @count.present? &&
                        @total_items.positive? && @count.positive?

        (@total_items.to_f / @count).ceil
      end
    end
  end
end
