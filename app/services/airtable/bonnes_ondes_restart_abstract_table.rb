Airrecord.api_key = ENV['AIRTABLE_API_KEY']

module Airtable
  class BonnesOndesRestartAbstractTable < Airrecord::Table
    self.base_key = ENV['AIRTABLE_BONNES_ONDES_RESTART']

    def self.by_dpt_and_stade dpts, stade
      dpts = dpts.map do |dpt|
        "{Dépt} = '#{dpt}'"
      end.join(', ')

      all(filter: "AND({Stade ?} = '#{stade}', OR(#{dpts}))")
    end

    def self.from_airtable dpts, stade
      # map = self.map
      # by_dpt_and_stade(dpt, stade).map(&:fields).map do |entoure|
      #   entoure.slice(map[:mobile], map[:email], map[:lastname], map[:firstname])
      # end.map(&:values)
      by_dpt_and_stade(dpts, stade).map(&:fields).map(&:values)
    end
  end
end
