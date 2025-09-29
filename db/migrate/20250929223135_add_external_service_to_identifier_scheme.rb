class AddExternalServiceToIdentifierScheme < ActiveRecord::Migration[6.1]
  def change
    add_column :identifier_schemes, :external_service, :string
  end
end
