# frozen_string_literal: true

module Api 
  module V2
    class TemplatesPolicy < ApplicationPolicy
      class Scope < Scope
        def initialize(resource_owner)
          @resource_owner = resource_owner
        end

        def resolve
          # create the sql where clause
          where_clause = <<-SQL
          (visibility = 0 AND org_id = ?) OR
          (visibility = 1 AND customization_of IS NULL)
          SQL

          # get the templates
          templates = Template.
            includes(org: :identifiers).
            joins(:org).
            published.
            where(
              where_clause, 
              @resource_owner.org&.id
            )
            .order(:title)
          templates
        end
      end
    end
  end
end