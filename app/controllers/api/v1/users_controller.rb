require 'typeform'

module Api
  module V1
    class UsersController < Api::V1::BaseController
      skip_before_filter :authenticate_user!, only: [:login, :code, :create, :lookup, :ethics_charter_signed]
      skip_before_filter :community_warning
      skip_before_filter :ensure_community!, only: :ethics_charter_signed
      skip_before_filter :protect_from_forgery, only: :ethics_charter_signed

      #curl -H "X-API-KEY:adc86c761fa8" -H "Content-Type: application/json" -X POST -d '{"user": {"phone": "+3312345567", "sms_code": "11111"}}' "http://localhost:3000/api/v1/login.json"
      def login
        user =
          if user_params.key?(:auth_token)
            error_message = "invalid auth_token"

            UserServices::UserAuthenticator.authenticate_with_token(
              auth_token: user_params[:auth_token],
              platform: api_request.platform
            )
          else
            unless PhoneValidator.new(phone: user_params[:phone]).valid?
              Rails.logger.info "SIGNIN_FAILED: invalid phone number format - params: #{params.inspect}"
              return render_error(code: "INVALID_PHONE_FORMAT", message: "invalid phone number format", status: 401)
            end

            secret_field =
              if api_request.platform == :web
                :secret
              else
                :sms_code
              end

            error_message = "wrong phone / #{secret_field}"

            UserServices::UserAuthenticator.authenticate(
              community: community,
              phone: user_params[:phone],
              secret: user_params[secret_field],
              platform: api_request.platform
            )
          end

        unless user
          Rails.logger.info "SIGNIN_FAILED: #{error_message} - params: #{params.inspect}"
          return render_error(code: "UNAUTHORIZED", message: error_message, status: 401)
        end

        if user.deleted || user.blocked?
          Rails.logger.info "SIGNIN_FAILED: deleted user - params: #{params.inspect}"
          return render_error(code: "DELETED", message: "user is deleted", status: 401)
        end

        user.update_column(:first_sign_in_at, Time.zone.now) if user.first_sign_in_at.nil?

        render json: user, status: 200, serializer: ::V1::UserSerializer, scope: full_user_serializer_options(current_user: user, displayed_user: user)
      end

      #curl -X PATCH -d '{"user": { "sms_code":"123456"}}' -H "Content-Type: application/json" "http://localhost:3000/api/v1/users/93.json?token=azerty"
      def update
        builder = UserServices::PublicUserBuilder.new(params: user_params, community: community)
        builder.update(user: @current_user, platform: api_request.platform) do |on|
          on.success do |user|
            mixpanel.sync_changes(user, {
              'first_name' => '$first_name',
              'email' => '$email'
            })

            render json: user, status: 200, serializer: ::V1::UserSerializer, scope: full_user_serializer_options(current_user: user, displayed_user: user)
          end

          on.failure do |user|
            render_error(code: "CANNOT_UPDATE_USER", message: user.errors.full_messages, status: 400)
          end
        end
      end

      #curl -X POST -d '{"user": { "phone":"+4068999999999"}}' -H "Content-Type: application/json" "http://localhost:3000/api/v1/users.json?token=azerty"
      def create
        builder = UserServices::PublicUserBuilder.new(params: user_params, community: community)
        builder.create(send_sms: true) do |on|
          on.success do |user|
            mixpanel.distinct_id = user.id
            mixpanel.track("Created Account")
            render json: user, status: 201, serializer: ::V1::UserSerializer, scope: { user: user }
          end

          on.failure do |user|
            Rails.logger.info "SIGNUP_FAILED: invalid params - params: #{params.inspect}"
            render_error(code: "CANNOT_CREATE_USER", message: user.errors.full_messages, status: 400)
          end

          on.duplicate do
            Rails.logger.info "SIGNUP_FAILED: phone number already exists - params: #{params.inspect}"
            render_error(code: "PHONE_ALREADY_EXIST", message: "Phone #{user_params["phone"]} n'est pas disponible", status: 400)
          end

          on.invalid_phone_format do
            Rails.logger.info "SIGNUP_FAILED: invalid phone number format - params: #{params.inspect}"
            render_error(code: "INVALID_PHONE_FORMAT", message: "Phone devrait être au format +33... ou 06...", status: 400)
          end
        end
      end

      def code
        if user_params[:phone].blank?
          return render json: {error: "Missing phone number"}, status:400
        end
        user_phone = Phone::PhoneBuilder.new(phone: user_params[:phone]).format
        user = community.users.where(phone: user_phone).first!

        if params[:code][:action] == "regenerate" && !user.deleted && !user.blocked?
          UserServices::SMSSender.new(user: user).regenerate_sms!
          render json: user, status: 200, serializer: ::V1::UserSerializer, scope: { user: user }
        else
          render json: {error: "Unknown action"}, status:400
        end
      end

      #curl -H "X-API-KEY:adc86c761fa8" -H "Content-Type: application/json" "http://localhost:3000/api/v1/users/me.json?token=azerty"
      def show
        user = params[:id] == "me" ? current_user : community.users.find(params[:id])
        render json: user, status: 200, serializer: ::V1::UserSerializer, scope: full_user_serializer_options(current_user: current_user, displayed_user: user)
      end

      def destroy
        UserServices::DeleteUserService.new(user: @current_user).delete
        render json: @current_user, status: 200, serializer: ::V1::UserSerializer, scope: { user: @current_user }
      end

      def report
        user = community.users.find(params[:id])
        reporter = UserServices::ReportUserService.new(reported_user: user, params: user_report_params)
        reporter.report(reporting_user: current_user) do |on|
          on.success do
            head :created
          end

          on.failure do |code|
            render json: { code: 'CANNOT_REPORT_USER' }, status: :bad_request
          end
        end
      end

      def presigned_avatar_upload
        user = params[:id] == "me" ? current_user : community.users.find(params[:id])
        if user != current_user
          return render_error(code: "UNAUTHORIZED", message: "You can only update your own avatar.", status: 401)
        end

        allowed_types = %w(image/jpeg image/gif)

        unless params[:content_type].in? allowed_types
          type_list = allowed_types.to_sentence(two_words_connector: ' or ', last_word_connector: ', or ')
          return render_error(code: "INVALID_CONTENT_TYPE", message: "Content-Type must be #{type_list}.", status: 400)
        end

        extension = MiniMime.lookup_by_content_type(params[:content_type]).extension
        key = "#{SecureRandom.uuid}.#{extension}"
        url = Storage::Client.avatars
          .object("300x300/#{key}")
          .presigned_url(
            :put,
            expires_in: 1.minute,
            acl: :private,
            content_type: params[:content_type],
            cache_control: "max-age=#{365.days}"
          )

        render json: { avatar_key: key, presigned_url: url }
      end

      def address
        updater = UserServices::AddressService.new(user: current_user, params: address_params)

        updater.update do |on|
          on.success do |user, address|
            render json: address, status: 200, serializer: ::V1::AddressSerializer
          end

          on.failure do |user, address|
            render_error(
              code: "CANNOT_UPDATE_ADDRESS",
              message: address.errors.full_messages +
                       user.errors.full_messages,
              status: 400
            )
          end
        end
      end

      def lookup
        unless PhoneValidator.new(phone: params[:phone]).valid?
          return render_error(code: "INVALID_PHONE_FORMAT", message: "invalid phone number format", status: 401)
        end

        user_phone = Phone::PhoneBuilder.new(phone: params[:phone]).format
        user = community.users.where(phone: user_phone).first

        reponse =
          if user.nil?
            {status: :not_found}
          elsif user.deleted || user.blocked?
            {status: :unavailable}
          else
            {status: :found, secret_type: user.has_password? ? :password : :code}
          end

        render json: reponse
      end

      def ethics_charter_signed
        answers = Typeform.answers params[:form_response]
        user_id = UserServices::EncodedId.decode answers['user_id']
        user = User.find(user_id)
        user.roles.push :ethics_charter_signed
        user.save!
      rescue => e
        Raven.capture_exception(e)
      ensure
        render nothing: true
      end

      private
      def user_params
        @user_params ||= params.require(:user).permit(:first_name, :last_name, :email, :sms_code, :password, :secret, :auth_token, :phone, :avatar_key, :about)
      end

      def user_report_params
        params.require(:user_report).permit(:message)
      end

      def address_params
        params.require(:address).permit(:place_name, :latitude, :longitude, :street_address, :google_place_id)
      end

      # The apps cache the response to /login and /update for the currentUser
      # so we want to make sure that all the fields necessary to render the profile
      # are included in the responses to thos requests
      def full_user_serializer_options current_user:, displayed_user:
        {
          full_partner: true,
          memberships: true,
          user: current_user,
          conversation: ConversationService.conversations_allowed?(from: current_user, to: displayed_user)
        }
      end
    end
  end
end
