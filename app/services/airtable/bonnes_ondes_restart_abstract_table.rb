Airrecord.api_key = ENV['AIRTABLE_API_KEY']

module Airtable
  class BonnesOndesRestartAbstractTable < Airrecord::Table
    self.base_key = ENV['AIRTABLE_BONNES_ONDES_RESTART']

    def self.by_dpt_and_stade dpts, stade
      dpts = dpts.map do |dpt|
        "{#{self.map[:dpt]}} = '#{dpt}'"
      end.join(', ')

      all(filter: "AND({#{self.map[:stade]}} = '#{stade}', OR(#{dpts}))")
    end

    # useful for "hors-zone" filter
    def self.by_not_in_dpt_and_stade dpts, stade
      not_dpts = dpts.map do |dpt|
        "NOT({#{self.map[:dpt]}} = '#{dpt}')"
      end.join(', ')

      all(filter: "AND({#{self.map[:stade]}} = '#{stade}', #{not_dpts})")
    end

    def self.from_airtable dpts, stade, hors_zone
      map = self.map

      records = hors_zone ? by_not_in_dpt_and_stade(dpts, stade) : by_dpt_and_stade(dpts, stade)

      records.map(&:fields).map do |people|
        people.slice(map[:mobile], map[:name], map[:dpt])
      end.map(&:values)
    end
  end
end
