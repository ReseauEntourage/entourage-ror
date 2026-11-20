module Assistant
  module Presenters
    # A request for help or an offer of help published by a member, as the app lists it.
    class HelpItem
      def initialize action
        @action = action
      end

      def as_json(*)
        {
          id: @action.uuid_v2,
          type: @action.contribution? ? 'offer' : 'request',
          title: @action.title.presence,
          description: @action.description.presence,
          category: section,
          createdAt: Support.iso8601(@action.created_at),
          author: Support.member(@action.user)
        }
      end

      private

      def section
        if @action.association(:section_taggings).loaded?
          @action.section_taggings.first&.tag&.name
        else
          @action.section_list.first
        end
      end
    end
  end
end
