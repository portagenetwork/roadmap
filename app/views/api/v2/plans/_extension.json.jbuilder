# frozen_string_literal: true

# locals: plan, presenter

json.extension [plan.template] do |template|
  json.set! :dmproadmap do
    json.template do
      json.id template.id
      json.title strip_tags(template.title)
    end
  end

  if @complete
    json.complete_plan do
      q_and_a = presenter.complete_plan_data
      next if q_and_a.blank?

      json.array! q_and_a do |item|
        json.question_id item[:id]
        json.title item[:title]
        json.section strip_tags(item[:section])
        json.question sanitize(item[:question])
        json.answer sanitize(item[:answer])
      end
    end
  end
end
