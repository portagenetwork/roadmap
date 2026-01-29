# frozen_string_literal: true

module Api
  module V2
    class TemplatesPolicy < ApplicationPolicy
      class Scope < Scope # rubocop:todo Style/Documentation
        def initialize(resource_owner) # rubocop:todo Lint/MissingSuper
          @resource_owner = resource_owner
        end

        def resolve
          # get the templates
          Template
            .includes(org: :identifiers)
            .joins(:org)
            .published
            .merge(accessible_templates)
            .order(:title)
        end

        private

        def accessible_templates
          org_templates = Template.organisationally_visible.where(org_id: @resource_owner.org&.id)
          public_templates = Template.publicly_visible.where(customization_of: nil)
          org_templates.or(public_templates)
        end
      end
    end
  end
end
