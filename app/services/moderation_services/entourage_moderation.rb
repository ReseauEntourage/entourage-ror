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

    def self.moderator_for_departement departement
      phone = {
        '75' => '+33111111111',
        '92' => '+33222222222',
        '69' => '+33333333333',
        '35' => '+33444444444',
        '59' => '+33666666666',
        nil  => '+33777777777'
      }
      phone = phone[departement] || phone[nil]
      User.find_by(community: :entourage, admin: true, phone: phone)
    end

    def assign_to_area_moderator entourage
      return unless entourage.group_type.in?(['action', 'outing'])
      return if entourage.country != 'FR'
      return if entourage.postal_code.nil?

      departement = entourage.postal_code.first(2)
      moderator = ModerationServices::EntourageModeration.moderator_for_departement(departement)

      entourage.moderation || entourage.build_moderation
      entourage.moderation.moderator_id = moderator.id
      entourage.moderation.save
    end

    def self.enable_callback
      !Rails.env.test?
    end

    module Callback
      extend ActiveSupport::Concern

      included do
        after_commit :assign_to_area_moderator
      end

      private

      def assign_to_area_moderator
        return unless ModerationServices::EntourageModeration.enable_callback
        return unless group_type.in?(['action', 'outing'])
        return unless postal_code.present?
        return if ::EntourageModeration.where(entourage_id: id).where.not(moderator_id: nil).exists?
        AsyncService.new(ModerationServices::EntourageModeration).assign_to_area_moderator(self)
      end
    end
  end
end
