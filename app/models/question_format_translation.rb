class QuestionFormatTranslation < ActiveRecord::Base
    include GlobalHelpers

    belongs_to :question_format


end
