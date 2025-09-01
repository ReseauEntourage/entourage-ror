module SmalltalkServices
  class Meeter
    class << self
      # due to Google API quota limits, we cannot create all Meets at once
      def schedule_meet_creation
        return unless meeting = Meeting.find_by_meet_link(nil)

        meeting.schedule_meet_creation
      end
    end
  end
end
