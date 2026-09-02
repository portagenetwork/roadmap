# frozen_string_literal: true

module Api
  module CommonMadmp
    # Helper class for generic API V2 pagination
    class PaginationPresenter
      def initialize(current_url:, count:, total_items:, current_page: 0)
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
        @offset.positive?
      end

      def next_page?
        return false unless @total_items.present? && @count.present?

        @offset + @count < @total_items
      end

      def prev_page_link
        page_link([@offset - @count, 0].max)
      end

      def next_page_link
        page_link(@offset + @count)
      end

      private

      def page_link(offset)
        "#{url_without_pagination}offset=#{offset}&count=#{@count}"
      end
    end
  end
end
