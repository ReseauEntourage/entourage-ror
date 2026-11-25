module Assistant
  module Presenters
    # The short form of an outing, in the lists of the assistant (search, activity). `placeLimit`
    # lets the assistant deduce the size of the outing; the number of registered people is counted
    # for the whole list in one query (see .counts).
    class EventBrief
      # Number of accepted participants per outing id, for a list of outings, in one query.
      def self.counts outings
        ::JoinRequest.accepted.where(joinable_type: 'Entourage', joinable_id: outings.map(&:id)).group(:joinable_id).count
      end

      def self.place outing
        return if outing.online

        outing.display_address.presence || outing.place_name.presence
      end

      def self.place_limit outing
        limit = outing.place_limit.to_i
        limit if limit.positive?
      end

      def initialize outing, participants_count:
        @outing = outing
        @participants_count = participants_count
      end

      def as_json(*)
        {
          id: outing.uuid_v2,
          title: outing.title.presence,
          startsAt: Support.iso8601(outing.starts_at),
          place: self.class.place(outing),
          participantsCount: @participants_count,
          placeLimit: self.class.place_limit(outing),
          reservedFemale: outing.reserved_female == true,
          format: outing.online ? 'online' : 'in_person'
        }
      end

      private

      attr_reader :outing
    end
  end
end
