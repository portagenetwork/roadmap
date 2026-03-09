# frozen_string_literal: true

module Api
  module V2
    # Sanitization service for API v2 serializers
    module SanitizationService
      # NOTE: We use the Rails::HTML5 sanitizer classes directly instead of the ActionView helpers:
      #
      #   sanitize(...)                      # from ActionView::Helpers::SanitizeHelper
      #   ActionView::Base.full_sanitizer    # strips all HTML
      #
      # Those helpers expect to run in an ActionView context and can raise errors when
      # called from plain Ruby classes (e.g., API presenters). Using Rails::HTML5::* works
      # consistently in presenters, helpers, and Jbuilder.
      #
      # We also pass the ActionView sanitizer config so the API follows the same allowlist
      # (`sanitized_allowed_tags` / `sanitized_allowed_attributes`) as the rest of the app.

      SAFE_LIST_SANITIZER = Rails::HTML5::SafeListSanitizer.new
      FULL_SANITIZER      = Rails::HTML5::FullSanitizer.new

      # Sanitizes HTML while preserving allowed formatting (e.g., TinyMCE output)
      def rich_text(value)
        return nil if value.nil?

        SAFE_LIST_SANITIZER.sanitize(
          value,
          tags: Rails.application.config.action_view.sanitized_allowed_tags,
          attributes: Rails.application.config.action_view.sanitized_allowed_attributes
        )
      end

      # Removes all HTML
      def plain_text(value)
        return nil if value.nil?

        FULL_SANITIZER.sanitize(value)
      end
    end
  end
end
