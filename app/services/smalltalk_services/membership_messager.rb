module SmalltalkServices
  class MembershipMessager
    attr_reader :entourage_user, :join_request

    def initialize join_request
      @entourage_user = User.find_entourage_user
      @join_request = join_request
    end

    def run
      return unless entourage_user
      return unless status_changed?

      return create_message(:new_member) if join_request.accepted?
      return create_message(:destroy_member) if join_request.cancelled?
      return create_message(:banned_member) if join_request.rejected?

      nil
    end

    private

    def create_message i18n_key, at = Time.zone.now
      SmalltalkAutoChatMessageJob.perform_at(at, join_request.id, i18n_key, username)
    end

    def username
      join_request.user.first_name
    end

    def status_changed?
      changes.key?("status")
    end

    def changes
      join_request.previous_changes
    end
  end
end
