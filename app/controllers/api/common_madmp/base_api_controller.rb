# frozen_string_literal: true

module Api
  module CommonMadmp
    class BaseApiController < Api::BaseApiController
      include Api::CommonMadmp::ErrorHandling
      include Api::CommonMadmp::Pagination
    end
  end
end
