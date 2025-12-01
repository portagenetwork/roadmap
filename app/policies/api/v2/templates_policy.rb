# frozen_string_literal: true

module Api
  module V2
    class TemplatesPolicy < ApplicationPolicy
      class Scope < Scope # rubocop:todo Style/Documentation
        def initialize(resource_owner) # rubocop:todo Lint/MissingSuper
          @resource_owner = resource_owner
        end

        def resolve
          # create the sql where clause
          where_clause = <<-SQL
          (visibility = 0 AND org_id = ?) OR
          (visibility = 1 AND customization_of IS NULL)
          SQL

          # get the templates
          Template
            .includes(org: :identifiers)
            .joins(:org)
            .published
            .where(
              where_clause,
              @resource_owner.org&.id
            )
            .order(:title)
        end
      end
    end
  end
end
