module Airtable
  class Entoures < BonnesOndesRestartAbstractTable
    def self.map
      {
        mobile: 'Téléphone portable',
        email: 'Mail',
        lastname: 'Nom',
        firstname: 'Prénom'
      }
    end

    def self.headers
      %w(Mobile Email Nom Prénom)
    end

    self.base_key = BonnesOndesRestartAbstractTable.base_key
    self.table_name = 'Entourés'
  end
end