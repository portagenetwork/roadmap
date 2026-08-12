# frozen_string_literal: true

# locals: phase

json.title strip_tags(phase[:title])
json.number phase[:number]

json.sections do
  json.array! phase[:sections] do |section|
    json.partial! 'api/v2/plan_snapshots/section',
                  section: section
  end
end
