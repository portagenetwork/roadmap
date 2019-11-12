class QuestionTranslation < ActiveRecord::Base
    include GlobalHelpers

    belongs_to :question


end
