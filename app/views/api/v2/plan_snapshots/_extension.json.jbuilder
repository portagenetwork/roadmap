# frozen_string_literal: true

# locals: presenter

template = presenter.template

json.template do
  json.id template[:id]
  json.title strip_tags(template[:title])
  json.version template[:version]

  json.phases do
    json.array! template[:phases] do |phase|
      json.partial! 'api/v2/plan_snapshots/phase',
                    phase: phase
    end
  end
end
