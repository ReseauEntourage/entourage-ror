module Assistant
  module Presenters
    # A request for help or an offer of help published by a member, as the assistant lists it:
    # its title and its category, and nothing about its author nor its text.
    class HelpItem
      def initialize action
        @action = action
      end

      def as_json(*)
        { id: @action.uuid_v2, title: @action.title.presence, category: section }
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
