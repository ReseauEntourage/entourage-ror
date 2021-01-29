module Airtable
  class Entoureurs < BonnesOndesRestartAbstractTable
    def self.map
      {
        mobile: 'Téléphone portable',
        name: 'Prénom Nom',
        dpt: 'Dépt',
        stade: 'Stade ?',
      }
    end

    def self.headers
      %w(Mobile Email Nom Prenom Departement)
    end

    self.base_key = BonnesOndesRestartAbstractTable.base_key
    self.table_name = 'Entoureurs'
  end
end
