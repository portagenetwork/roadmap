# frozen_string_literal: true

# locals: question

json.id question[:id]
json.number question[:number]
json.text sanitize(question[:text])

if question[:format]
  json.format do
    json.id question[:format][:id]
    json.title question[:format][:title]
  end
end

json.answer do
  json.text sanitize(question[:answer][:text])
end
