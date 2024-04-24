module OrganizationAdmin
  class SessionsController < BaseController
    skip_before_action :authenticate_user!, :ensure_org_member!

    layout_options(menu: false, partner_name: false, exit_admin: false)

    def identify
      @phone = Phone::PhoneBuilder.new(phone: params[:phone]).format
      user = community.users.where(phone: @phone).first

      if user.nil?
        builder = UserServices::PublicUserBuilder.new(
          community: community,
          params: {phone: @phone}
        )
        error = nil
        builder.create(send_sms: true) do |on|
          on.invalid_phone_format { error = :invalid_phone_format }

          on.duplicate { raise "This should never happen" }

          on.failure do |user|
            Raven.capture_exception(ActiveRecord::RecordInvalid.new(user))
            error = :unknown
          end

          on.success do |new_user|
            user = new_user
          end
        end

        if error != nil
          # for now this flow is only used in the context of an invitation
          raise unless params[:continue].present?

          # @caution ugly. for now, params[:continue] will always be a path without query string
          return redirect_to [params[:continue], '?', {error: error, phone: params[:phone]}.to_query].join
        end

        @context = :new_sms_code
      elsif user == current_user
        return redirect_to params[:continue]
      elsif user.has_password?
        @context = :login_password
      elsif params[:context] == 'new_sms_code'
        @context = :new_sms_code
      elsif params[:context] == 'new_sms_code_second_try'
        @context = :new_sms_code
        @new_sms_code_second_try = true
      else
        @context = :existing_sms_code
      end

      raise "blocked|deleted" if user.deleted? || user.blocked?
    end

    def authenticate
      unless params[:method].in?(['sms_code', 'password'])
        raise "unexpected method"
      end

      user = UserServices::UserAuthenticator.authenticate(
        community: community,
        phone: params[:phone],
        secret: params[params[:method]],
        platform: :web
      )

      if user.nil?
        redirect_to identify_organization_admin_session_path(
          phone: params[:phone],
          continue: params[:continue],
          error: :login_failure,
        )
        return
      end

      raise "blocked|deleted" if user.deleted? || user.blocked?
      sign_in(user)
      user.update_column(:first_sign_in_at, Time.zone.now) if user.first_sign_in_at.nil?

      redirect_to params[:continue].presence || organization_admin_path
    end

    def reset_password
      phone = Phone::PhoneBuilder.new(phone: params[:phone]).format
      user = community.users.where(phone: phone).first
      raise "This should never happen" if user.nil?
      raise "blocked|deleted" if user.deleted? || user.blocked?

      UserServices::SmsSender.new(user: user)
        .regenerate_sms!(clear_password: true)

      context =
        if params[:context] == 'second_try'
          :new_sms_code_second_try
        else
          :new_sms_code
        end

      redirect_to identify_organization_admin_session_path(
        phone: user.phone,
        continue: params[:continue],
        context: context
      )
    end

    def logout
      sign_out
      redirect_to ENV['WEBSITE_URL'] + '/app?org_admin_logout'
    end
  end
end
