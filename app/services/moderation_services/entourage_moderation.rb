module ModerationServices
  module EntourageModeration
    module_function

    def moderator_for entourage
      ModerationServices.moderator_if_exists(community: entourage.community)
    end

    def on_create entourage
      moderator = moderator_for(entourage)
      return if moderator.nil?
      JoinRequestsServices::AdminAcceptedJoinRequestBuilder
        .new(joinable: entourage, user: moderator)
        .create
    end

    def assign_to_area_moderator entourage
      moderator = ModerationServices.moderator_for_entourage(entourage)

      return if moderator.nil?

      entourage.moderation || entourage.build_moderation
      entourage.moderation.moderator_id = moderator.id
      entourage.moderation.save
    rescue ActiveRecord::RecordNotUnique
      # a concurrent request already created the moderation row for this entourage;
      # reload it and apply our change on top instead of trying to insert a duplicate
      entourage.association(:moderation).reset
      entourage.moderation&.update(moderator_id: moderator.id)
    end

    def assign_section entourage
      # set section from either section or display_category
      section = Tag.section_list_for(entourage).first ||
        ActionServices::Mapper.section_from_display_category(entourage.display_category)

      entourage.moderation || entourage.build_moderation
      entourage.moderation.section = section
      entourage.moderation.save
    rescue ActiveRecord::RecordNotUnique
      entourage.association(:moderation).reset
      entourage.moderation&.update(section: section)
    end

    module Callback
      extend ActiveSupport::Concern

      included do
        after_commit :assign_to_area_moderator
        after_commit :assign_section
      end

      private

      def assign_to_area_moderator
        return unless action? || outing?
        return unless (['country', 'postal_code'] & previous_changes.keys).any?
        return unless [country, postal_code].all?(&:present?)
        return if ::EntourageModeration.where(entourage_id: id).where.not(moderator_id: nil).exists?

        ModerationServices::EntourageModeration.assign_to_area_moderator(self)
      end

      def assign_section
        return unless action?
        return if ::EntourageModeration.where(entourage_id: id).where.not(moderator_id: nil).exists?

        ModerationServices::EntourageModeration.assign_section(self)
      end
    end
  end
end
