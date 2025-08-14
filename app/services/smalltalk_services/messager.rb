module SmalltalkServices
  class Messager
    attr_reader :entourage_user, :smalltalk, :verb

    def initialize smalltalk, verb
      @entourage_user = User.find_entourage_user
      @smalltalk = smalltalk
      @verb = verb
    end

    def run
      return unless entourage_user

      return run_after_create if create?
      return run_complete if completed_at_changed?
    end

    def run_after_create
      return create_message(:incomplete) if smalltalk.incomplete?

      run_complete(now)
    end

    def run_complete time = nil
      complete_time = time || now.change(hour: 18, min: 0, sec: 0)
      complete_time += 1.day if complete_time < now

      create_message(:complete, at: complete_time, i18n_arg: smalltalk.meeting_url)
      create_message(:complete_j1, at: (Time.zone.now + 1.days).change(hour: 10, min: 0))
      create_message(:complete_j2, at: (Time.zone.now + 2.days).change(hour: 10, min: 0))
      create_message(:complete_j3, at: (Time.zone.now + 3.days).change(hour: 10, min: 0))
      create_message(:complete_j4, at: (Time.zone.now + 4.days).change(hour: 10, min: 0))
      create_message(:complete_j5, at: (Time.zone.now + 5.days).change(hour: 10, min: 0))
      create_message(:complete_j6, at: (Time.zone.now + 6.days).change(hour: 10, min: 0))
      create_message(:complete_j7, at: (Time.zone.now + 7.days).change(hour: 10, min: 0))
      create_message(:complete_j21, at: (Time.zone.now + 21.days).change(hour: 18, min: 0))
    end

    private

    def create_message i18n_key, at: Time.zone.now, i18n_arg: nil
      SmalltalkAutoChatMessageJob.perform_at(at, smalltalk.id, i18n_key.to_s, i18n_arg.to_s)
    end

    def create?
      verb == :create
    end

    def completed_at_changed?
      changes.key?("completed_at") && changes["completed_at"].first.nil?
    end

    def changes
      smalltalk.previous_changes
    end

    def now
      @now ||= Time.zone.now
    end
  end
end
