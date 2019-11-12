class VersionTranslation < ActiveRecord::Base
    include GlobalHelpers

    belongs_to :version


end
