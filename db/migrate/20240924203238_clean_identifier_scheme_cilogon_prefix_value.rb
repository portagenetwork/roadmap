class CleanIdentifierSchemeCilogonPrefixValue < ActiveRecord::Migration[6.1]
  def up
    scheme = IdentifierScheme.find_by(name: 'openid_connect')
    if scheme
      scheme.identifier_prefix = ''
      scheme.save!
    end

    Identifier.where("value ~* ?", 'http://cilogon.+cilogon.+').each do |identifier|
      identifier.value.delete_prefix!('http://cilogon.org/serverE/users/')
      identifier.save!
    end
  end

  def down
    scheme = IdentifierScheme.find_by(name: 'openid_connect')
    if scheme
      scheme.identifier_prefix = 'http://cilogon.org/serverE/users/'
      scheme.save!
    end
  end
end
