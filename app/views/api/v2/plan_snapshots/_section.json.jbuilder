# frozen_string_literal: true

# locals: section

json.title strip_tags(section[:title])
json.number section[:number]
json.modifiable section[:modifiable]

json.questions do
  json.array! section[:questions] do |question|
    json.partial! 'api/v2/plan_snapshots/question',
                  question: question
  end
end
