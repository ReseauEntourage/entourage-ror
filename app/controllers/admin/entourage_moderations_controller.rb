module Admin
  class EntourageModerationsController < Admin::BaseController
    before_action :set_entourage, only: [:update]

    def create
      entourage = Entourage.find(moderation_params[:entourage_id])
      moderation = entourage.moderation || entourage.build_moderation
      user_moderation = entourage.user_moderation || entourage.build_user_moderation

      moderation.assign_attributes(moderation_params)
      user_moderation.assign_attributes(user_moderation_params)

      saved = false
      ActiveRecord::Base.transaction do
        moderation.save!
        user_moderation.save!
        saved = true
      end

      if saved
        head :ok
      else
        head :unprocessable_entity
      end
    end

    private

    def moderation_params
      params.require(:entourage_moderation).permit(
        :entourage_id,
        :action_author_type, :action_recipient_type, :action_type, :action_recipient_consent_obtained,
        :moderated_at, :moderation_contact_channel, :moderator, :moderation_action, :moderation_comment,
        :action_outcome_reported_at, :action_outcome, :action_success_reason, :action_failure_reason,
      )
    end

    def user_moderation_params
      params.require(:user_moderation).permit(
        :expectations, :acquisition_channel, :content_sent, :skills
      )
    end
  end
end
