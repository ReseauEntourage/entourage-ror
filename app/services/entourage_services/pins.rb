module EntourageServices
  class Pins
    def self.find user, types
      return [] if user.community != :entourage

      pinned = []

      if (types.nil? || types.any? { |t| t.starts_with?('ask_for_help_') || t.starts_with?('contribution_') })
        pinned << self.neighborhood_group_for(user)
      end

      if (types.nil? || types.include?('outing'))
        pinned << 121064 # Atelier solidaire : 1h pour comprendre comment aider les personnes SDF
      end

      pinned
    end

    NEIGHBORHOOD_GROUPS = Hash[{
      ['75005', '75006', '75007', '75013', '75014', '75015'] => 110026, # Paris Sud
      ['75001', '75002', '75008', '75009', '75016', '75017', '75018'] => 110032, # Paris Ouest
      ['75003', '75004', '75010', '75011', '75012', '75019', '75020'] => 110033, # Paris Est
      ['92110', '92300', '92600', '92230'] => 110016, # Clichy-Levallois
      ['92000', '92400', '92800', '92200', '92250', '92700', '92150'] => 110060, # La Défense
      ['69'] => 110057, # Lyon
      ['59'] => 110059, # Lille
      ['35'] => 110053, # Rennes
      ['13000', '13001', '13002', '13003', '13004', '13005', '13006', '13007', '13008', '13009', '13010', '13011', '13012', '13013', '13014', '13015', '13016'] => 113230, # Marseille
      ['33000', '33100', '33200', '33300', '33800'] => 112941, # Bordeaux
      ['31000', '31100', '31200', '31300', '31400', '31500'] => 112945, # Toulouse
      ['34000', '34070', '34080', '34090'] => 113231, # Montpellier
      ['44000', '44100', '44200', '44300'] => 113233, # Nantes
      ['06000', '06100', '06200', '06300'] => 113234, # Nice
      ['67000', '67100', '67200'] => 113232, # Strasbourg
    }.flat_map { |ks, v| ks.map { |k| [k, v] }}].freeze

    def self.neighborhood_group_for user
      return if user.address.nil?
      return if user.address.country != 'FR'

      postal_code = user.address.postal_code.to_s
      departement = postal_code.first(2)

      entourage_id = NEIGHBORHOOD_GROUPS[postal_code] || NEIGHBORHOOD_GROUPS[departement]
      return if entourage_id.nil?
      entourage_id
    end
  end
end
