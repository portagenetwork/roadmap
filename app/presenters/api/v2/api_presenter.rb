# frozen_string_literal: true

module Api
  module V2
    # Generic helper methods for API V2
    class ApiPresenter
      class << self
        def boolean_to_yes_no_unknown(value:)
          return 'yes' if value == true
          return 'no' if value == false

          'unknown'
        end
      end
    end
  end
end
