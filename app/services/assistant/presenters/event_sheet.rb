module Assistant
  module Presenters
    # The sheet of an outing: what it contains and nothing more. A missing information is returned
    # as missing (null), never completed. The charte is not here: it lives in the apps.
    #
    # `subjectId` is the stable identifier of the event, the subject of the anonymous measures kept
    # by the assistant: it does not point to any person. `meetingType` is the type of meeting.
    class EventSheet
      def initialize outing, participants_count:
        @outing = outing
        @participants_count = participants_count
      end

      def as_json(*)
        {
          id: outing.uuid_v2,
          title: outing.title.presence,
          description: outing.description.presence,
          startsAt: Support.iso8601(outing.starts_at),
          endsAt: Support.iso8601(outing.ends_at),
          durationMinutes: duration_minutes,
          place: EventBrief.place(outing),
          organizerName: outing.user && Support.display_name(outing.user),
          participantsCount: @participants_count,
          placeLimit: EventBrief.place_limit(outing),
          format: outing.online ? 'online' : 'in_person',
          reservedFemale: outing.reserved_female == true,
          subjectId: outing.uuid_v2,
          meetingType: meeting_type
        }
      end

      private

      attr_reader :outing

      def duration_minutes
        starts_at = parse(outing.starts_at)
        ends_at = parse(outing.ends_at)
        return unless starts_at && ends_at && ends_at >= starts_at

        ((ends_at - starts_at) / 60).round
      end

      def parse value
        return if value.blank?

        value.respond_to?(:to_time) && !value.is_a?(String) ? value.to_time : Time.zone.parse(value.to_s)
      rescue ArgumentError
        nil
      end

      # The category of the event when it has one, a papotage otherwise recognized by the app,
      # else a plain event.
      def meeting_type
        outing.sf_category.presence || (outing.papotage? ? 'papotage' : 'event')
      end
    end
  end
end
