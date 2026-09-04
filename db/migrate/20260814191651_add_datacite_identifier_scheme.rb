class AddDataciteIdentifierScheme < ActiveRecord::Migration[6.1]
  def up
    datacite = IdentifierScheme.find_or_initialize_by(name: 'datacite')
    datacite.description = 'DataCite DOI Repository'
    datacite.active = true
    datacite.for_plans = true
    datacite.for_plan_snapshots = true
    datacite.identifier_prefix = 'https://doi.org/'
    datacite.save!
  end

  def down
    IdentifierScheme.find_by(name: 'datacite')&.destroy
  end
end
