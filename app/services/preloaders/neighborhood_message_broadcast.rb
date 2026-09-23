module Preloaders
  module NeighborhoodMessageBroadcast
    # recipient ids, names and number of people of a list of broadcasts, with two queries instead
    # of several per broadcast (@see NeighborhoodMessageBroadcast#recipient_ids, #recipients_number_of_people)
    def self.preload_recipients broadcasts
      broadcasts = broadcasts.to_a.grep(::NeighborhoodMessageBroadcast)
      return if broadcasts.empty?

      preload_departement_selections(broadcasts.select(&:is_departement_selection?))

      recipients_by_id = ::Neighborhood
        .where(id: broadcasts.flat_map(&:recipient_ids).uniq)
        .order(:id)
        .pluck(:id, :name, :number_of_people)
        .to_h { |id, name, number_of_people| [id, { name: name, number_of_people: number_of_people }] }

      broadcasts.each do |broadcast|
        broadcast.preloaded_recipients = recipients_by_id.slice(*broadcast.recipient_ids).values
      end
    end

    # the same scope as NeighborhoodMessageBroadcast#neighborhood_ids_in_departements_and_area_type,
    # for every broadcast, in a single UNION ALL query
    def self.preload_departement_selections broadcasts
      return if broadcasts.empty?

      sql = broadcasts.map do |broadcast|
        ::NeighborhoodMessageBroadcast
          .neighborhoods_in_departements_and_area_type(broadcast.departements, broadcast.area_type)
          .select(:id, Arel.sql("#{Integer(broadcast.id)} AS broadcast_id"))
          .to_sql
      end.join(' UNION ALL ')

      ids_by_broadcast_id = ActiveRecord::Base.connection.select_rows(sql).group_by(&:last)

      broadcasts.each do |broadcast|
        broadcast.preloaded_recipient_ids = (ids_by_broadcast_id[broadcast.id] || []).map(&:first)
      end
    end
  end
end
