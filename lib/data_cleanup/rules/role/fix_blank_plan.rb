# frozen_string_literal: true
module DataCleanup
  module Rules
    # Fix blank plan on Role
    module Role
      class FixBlankPlan < Rules::Base

        def description
          "Fix blank plan on Role"
        end

        def call
          ids = ::Role.where(plan: nil).ids
          log("Destroying Roles without Plan: #{ids}")
          ::Role.destroy(ids)
        end
      end
    end
  end
end
