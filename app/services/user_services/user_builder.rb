require "securerandom"

module UserServices
  class UserBuilder
    def initialize(params:)
      params ||= {}
      @params = params
      @callback = UserServices::UserBuilderCallback.new
    end

    def token
      SecureRandom.hex(16)
    end

    def create(send_sms: false, sms_code: nil)
      yield callback if block_given?

      return callback.on_invalid_phone_format unless LegacyPhoneValidator.new(phone: params[:phone]).valid?

      sms_code = sms_code || UserServices::SmsCode.new.code
      user = new_user(sms_code)
      UserService.sync_roles(user)
      if user.save
        self.class.process_good_waves_invitations(user)

        UserServices::SMSSender.new(user: user).send_welcome_sms(sms_code) if send_sms
        MemberMailer.welcome(user).deliver_later if user.email.present?

        signal_association(user)

        callback.on_success.try(:call, user)
      else
        return callback.on_duplicate(user) if User.where(phone: params[:phone]).count>0
        callback.on_failure.try(:call, user)
      end
      user
    rescue ActiveRecord::RecordNotUnique
      callback.on_duplicate(user)
    end

    def signal_blocked_user user
      return unless user.email.present?
      return unless user.saved_change_to_email?

      blocked_user_ids = User.where(validation_status: :blocked, email: user.email).pluck(:id)

      return if blocked_user_ids.empty?

      SlackServices::SignalUserCreation.new(user: user, blocked_user_ids: blocked_user_ids).notify
    end

    def signal_association user
      return unless user.saved_change_to_goal?
      return unless user.goal_association?

      SlackServices::SignalAssociationCreation.new(user: user).notify
    end

    private
    attr_reader :params, :callback

    def new_user
      raise "should be overriden by subclasses"
    end

    def self.process_good_waves_invitations user
      pending_invitations = EntourageInvitation.where(
        invitation_mode: :good_waves,
        phone_number: user.phone,
        status: :pending,
      )

      invitations_entourage_ids = pending_invitations.pluck(:invitable_id)

      joined_entourages_ids = user.join_requests.where(joinable_type: :Entourage).pluck(:joinable_id)

      non_joined_entourages_ids = invitations_entourage_ids - joined_entourages_ids

      pending_invitations.where(invitable_id: non_joined_entourages_ids).each do |invitation|
        jr = JoinRequest.new(
          user_id: user.id,
          joinable_type: invitation.invitable_type,
          joinable_id: invitation.invitable_id,
          role: :member,
          status: :accepted
        )
        if jr.save
          FeedUpdatedAt.update(
            invitation.invitable_type,
            invitation.invitable_id,
            jr.created_at
          )
          invitation.update_columns(
            status: :accepted,
            invitee_id: user.id
          )
        else
          Raven.capture_exception(ActiveRecord::RecordInvalid.new(jr))
        end
      end
    end
  end
end
