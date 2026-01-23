module SmalltalkServices
  class Inactivity
    attr_reader :days, :event, :i18n_key

    def initialize days
      @days = days
      @event = "inactive_j#{days}"
    end

    def chat_messages!
      smalltalks.each do |smalltalk|
        SmalltalkAutoChatMessageJob.new.perform(
          smalltalk.id,
          event,
          smalltalk.meeting_url
        )
      end
    end

    private

    def smalltalks
      Smalltalk
        .complete
        .having_last_message_during_day(days.days.ago)
        .without_event(event)
    end
  end
end
