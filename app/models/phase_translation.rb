class PhaseTranslation < ActiveRecord::Base
    include GlobalHelpers

    belongs_to :phase


end
