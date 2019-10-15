module Admin
  class EntourageModerationsController < Admin::BaseController
    before_action :set_entourage, only: [:update]

    def create
      entourage = Entourage.find(moderation_params[:entourage_id])
      moderation = entourage.moderation || entourage.build_moderation
      user_moderation = entourage.user_moderation || entourage.build_user_moderation
      user = entourage.user

      moderation.assign_attributes(moderation_params)
      user_moderation.assign_attributes(user_moderation_params)
      user.assign_attributes(user_params)

      saved = true
      saved &&= moderation.save if moderation.changed?
      saved &&= user_moderation.save if user_moderation.changed?
      saved &&= user.save if user.changed?

      if saved
        head :ok
      else
        render status: :unprocessable_entity, json: {
          entourage_moderation: moderation.errors.messages,
          user_moderation: user_moderation.errors.messages,
          user: user.errors.messages
        }
      end
    end

    private

    def moderation_params
      params.require(:entourage_moderation).permit(
        :entourage_id,
        :action_author_type, :action_recipient_type, :action_target_type, :action_type, :action_recipient_consent_obtained,
        :moderated_at, :moderation_contact_channel, :moderator_id, :moderation_comment,
        :action_outcome_reported_at, :action_outcome, :action_success_reason, :action_failure_reason,
      )
    end

    def user_moderation_params
      params.require(:user_moderation).permit(
        :skills
      )
    end

    def user_params
      params.require(:user).permit(
        :targeting_profile, :partner_id
      )
    end
  end
end
