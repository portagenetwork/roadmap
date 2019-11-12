class GuidanceTranslation < ActiveRecord::Base
    include GlobalHelpers

    belongs_to :guidance

end
