module Assistant
  module Presenters
    # Small helpers shared by the presenters of the assistant. Every presenter has a closed list of
    # fields, written by hand: nothing is delegated to a serializer of the app, so that a field
    # added there one day never reaches the assistant (and its language model).
    module Support
      module_function

      def iso8601 value
        return if value.blank?

        time = value.respond_to?(:iso8601) ? value : Time.zone.parse(value.to_s)
        time&.iso8601
      rescue ArgumentError
        nil
      end

      def display_name user
        UserPresenter.new(user: user).display_name
      end

      # What the app shows of a member: its uuid and its display name.
      def member user
        return unless user

        { id: user.uuid, displayName: display_name(user) }
      end
    end
  end
end
