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
      return run_complete if complete?
    end

    def run_after_create
      return create_message(:incomplete) if smalltalk.incomplete?

      run_complete(now)
    end

    def run_complete time = nil
      complete_time = time || now.change(hour: 18, min: 0, sec: 0)
      complete_time += 1.day if complete_time < now

      create_message(:complete, complete_time)
      create_message(:complete_j1, (Time.zone.now + 1.days).change(hour: 10, min: 0))
      create_message(:complete_j2, (Time.zone.now + 2.days).change(hour: 10, min: 0))
      create_message(:complete_j3, (Time.zone.now + 3.days).change(hour: 10, min: 0))
      create_message(:complete_j4, (Time.zone.now + 4.days).change(hour: 10, min: 0))
      create_message(:complete_j5, (Time.zone.now + 5.days).change(hour: 10, min: 0))
      create_message(:complete_j6, (Time.zone.now + 6.days).change(hour: 10, min: 0))
      create_message(:complete_j7, (Time.zone.now + 7.days).change(hour: 10, min: 0))
      create_message(:complete_j21, (Time.zone.now + 21.days).change(hour: 18, min: 0))
    end

    private

    def create_message i18n_key, at = Time.zone.now
      SmalltalkAutoChatMessageJob.perform_at(at, smalltalk.id, i18n_key, nil)
    end

    def create?
      verb == :create
    end

    def complete?
      return unless smalltalk.many?
      return unless completed_at_changed? # ensures run_complete is called only one time

      smalltalk.complete?
    end

    def number_of_people_changed?
      changes.key?("number_of_people")
    end

    def completed_at_changed?
      changes.key?("completed_at") && changes["completed_at"].first.nil?
    end

    def number_of_people_changed_up?
      changes["number_of_people"].present? && changes["number_of_people"].last > changes["number_of_people"].first
    end

    private

    def changes
      smalltalk.changes
    end

    def now
      @now ||= Time.zone.now
    end
  end
end
