require 'typeform'

module Api
  module V1
    class UsersController < Api::V1::BaseController
      skip_before_action :authenticate_user!, only: [:login, :code, :request_phone_change, :create, :lookup, :ethics_charter_signed, :update_email_preferences, :confirm_address_suggestion]
      skip_before_action :community_warning
      skip_before_action :ensure_community!, only: :ethics_charter_signed
      allow_anonymous_access only: [:show, :report, :address]

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
            unless LegacyPhoneValidator.new(phone: user_params[:phone]).valid?
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

        if user.first_sign_in_at.nil?
          user.update_column(:first_sign_in_at, Time.zone.now)
          first_sign_in = true
        else
          first_sign_in = false
        end

        render status: 200, json: {
          user: ::V1::UserSerializer.new(user, scope: full_user_serializer_options(current_user: user, displayed_user: user), root: false),
          first_sign_in: first_sign_in
        }
      end

      #curl -X PATCH -d '{"user": { "sms_code":"123456"}}' -H "Content-Type: application/json" "http://localhost:3000/api/v1/users/93.json?token=azerty"
      def update
        builder = UserServices::PublicUserBuilder.new(params: update_params, community: community)
        builder.update(user: @current_user, platform: api_request.platform) do |on|
          on.success do |user|
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
            render json: user, status: 201, serializer: ::V1::Users::PhoneOnlySerializer
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
          return render json: {error: "Missing phone number"}, status: 400
        end

        user_phone = Phone::PhoneBuilder.new(phone: user_params[:phone]).format
        user = community.users.where(phone: user_phone).first

        if user.nil?
          return render_error(code: "USER_NOT_FOUND", message: "", status: 404)
        end

        if params[:code][:action] == "regenerate" && !user.deleted && !user.blocked?
          UserServices::SmsSender.new(user: user).regenerate_sms!(clear_password: api_request.platform == :web)
          render json: user, status: 200, serializer: ::V1::Users::PhoneOnlySerializer
        else
          render json: {error: "Unknown action"}, status: 400
        end
      end

      def request_phone_change
        if user_params[:current_phone].blank? || user_params[:requested_phone].blank?
          return render json: { error: "Veuillez vérifier vos numéros de téléphone" }, status: 400
        end

        user_phone = Phone::PhoneBuilder.new(phone: user_params[:current_phone]).format
        user = community.users.where(phone: user_phone).first

        if user.nil?
          return render_error(code: "USER_NOT_FOUND", message: "L'ancien numéro est inconnu. Veuillez vérifier", status: 404)
        end

        if user.deleted
          return render_error(code: "USER_DELETED", message: "L'ancien numéro a été supprimé. Veuillez vérifier", status: 404)
        end

        if user.blocked?
          return render_error(code: "USER_BLOCKED", message: "L'ancien numéro a été bloqué. Veuillez vérifier", status: 404)
        end

        if user_phone == Phone::PhoneBuilder.new(phone: user_params[:requested_phone]).format
          return render_error(code: "IDENTICAL_PHONES", message: "Les deux numéros sont identiques. Veuillez vérifier le nouveau numéro", status: 404)
        end

        UserServices::RequestPhoneChange.new(user: user).request(requested_phone: user_params[:requested_phone], email: user_params[:email])
        render json: { code: "SENT", message: "Votre demande de changement de numéro de téléphone a été envoyée" }, status: 200
      end

      #curl -H "X-API-KEY:adc86c761fa8" -H "Content-Type: application/json" "http://localhost:3000/api/v1/users/me.json?token=azerty"
      def show
        user =
          if params[:id] == "me" ||
             params[:id] == UserService.external_uuid(current_user_or_anonymous)
            current_user_or_anonymous
          else
            community.users.find(params[:id])
          end

        render json: user, root: :user, status: 200, serializer: ::V1::UserSerializer, scope: full_user_serializer_options(current_user: current_user_or_anonymous, displayed_user: user)
      end

      def unread
        render json: current_user, root: :user, status: 200, serializer: ::V1::Users::UnreadSerializer
      end

      def destroy
        UserServices::DeleteUserService.new(user: @current_user).delete
        render json: @current_user, status: 200, serializer: ::V1::UserSerializer, scope: { user: @current_user }
      end

      def report
        user = community.users.find(params[:id])
        reporter = UserServices::ReportUserService.new(reported_user: user, params: user_report_params)
        reporter.report(reporting_user: current_user_or_anonymous) do |on|
          on.success do
            head :created
          end

          on.failure do |message|
            render json: { code: 'CANNOT_REPORT_USER', message: message }, status: :bad_request
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
            expires_in: 1.minute.to_i,
            acl: :private,
            content_type: params[:content_type],
            cache_control: "max-age=#{365.days}"
          )

        render json: { avatar_key: key, presigned_url: url }
      end

      def address
        if !params[:id].in?(['me', UserService.external_uuid(current_user_or_anonymous)])
          return render_error(code: "UNAUTHORIZED", message: "You can only update your own address.", status: 401)
        end

        updater = UserServices::AddressService.new(user: current_user_or_anonymous, position: 1, params: address_params)

        updater.update do |on|
          on.success do |user, address|
            render status: 200, json: {
              address: ::V1::AddressSerializer.new(address, root: false),
              firebase_properties: UserService.firebase_properties(user)
            }
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

      def following
        if !params[:id].in?(['me', UserService.external_uuid(current_user_or_anonymous)])
          return render_error(code: "UNAUTHORIZED", message: "You can only update your own followings.", status: 401)
        end

        partner_id = following_params[:partner_id]
        if Partner.where(id: partner_id).exists? == false
          return render_error(code: "PARTNER_NOT_FOUND", message: "Partner not found for partner_id: #{partner_id.inspect}.", status: 404)
        end

        following = Following.find_or_initialize_by(user_id: current_user.id, partner_id: partner_id)
        following.active = following_params[:active]

        success =
          if following.new_record? && following.active == false
            # no need to create an inactive following
            true
          else
            following.save
          end

        if success
          render status: 200, json: {following: {partner_id: following.partner_id, active: following.active}}
        else
          render_error(code: "CANNOT_UPDATE_FOLLOWING", message: following.errors.full_messages, status: 400)
        end
      end

      def lookup
        unless LegacyPhoneValidator.new(phone: params[:phone]).valid?
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

      def update_email_preferences
        @user = User.find(params[:id])

        @category = params.key?(:category) ? params[:category]&.to_sym : :all

        unless EmailPreferencesService.categories.include?(@category) ||
               @category == :all
          @success = false
          return render layout: 'landing'
        end

        if SignatureService.validate(@user.id, params[:signature]) &&
           EmailPreferencesService.update_subscription(
            user: @user, category: @category, subscribed: params[:accepts_emails])
          @success = true
          @accepts_emails = EmailPreferencesService.accepts_emails?(
            user: @user, category: @category)
        else
          @success = false
        end

        render layout: 'landing'
      end

      def confirm_address_suggestion
        @user = User.find(params[:id])
        @postal_code = params[:postal_code]

        # temporary workaround for a borked email
        if @postal_code.nil? && @user.address&.postal_code.present?
          @postal_code = @user.address&.postal_code
        end

        unless @postal_code.match?(/\A\d[1-9]\d\d\d\z/)
          @status = :error
          return render layout: 'landing'
        end

        signature_key = UserServices::AddressService.confirm_url_key(
          user_id: @user.id, postal_code: @postal_code)
        unless SignatureService.validate(signature_key, params[:signature])
          @status = :error
          return render layout: 'landing'
        end

        if @user.address&.postal_code == @postal_code
          @status = :success
          return render layout: 'landing'
        end

        if request.post?
          address_params = {
            place_name: @postal_code,
            postal_code: @postal_code,
            country: :FR
          }

          updater = UserServices::AddressService.new(user: @user, position: 1, params: address_params)

          updater.update do |on|
            on.success do |user, address|
              return redirect_to UserServices::AddressService.confirm_url(
                user: @user, postal_code: @postal_code)
            end

            on.failure do |user, address|
              @status = :error
            end
          end
        else
          @status = :display_form
        end

        render layout: 'landing'
      end

      def ethics_charter_signed
        answers = Typeform.answers params[:form_response]
        # Typeform::answers does not return a user_id
        # @deprecated this method seems deprecated
        user_id = UserServices::EncodedId.decode answers['user_id']
        user = User.find(user_id)
        user.roles.push :ethics_charter_signed
        user.save!
      rescue => e
        Raven.capture_exception(e)
      ensure
        head :ok
      end

      def organization_admin_redirect
        if current_user.partner.nil?
          return head :ok
        end

        message = params[:message] if params[:message].in?(['webapp_logout'])

        auth_token = UserServices::UserAuthenticator.auth_token(current_user, expires_in: 5.seconds)
        redirect_to organization_admin_auth_url(auth_token: auth_token, message: message)
      end

      private
      def user_params
        @user_params ||= params.require(:user).permit(:first_name, :last_name, :email, :sms_code, :password, :secret, :auth_token, :phone, :current_phone, :requested_phone, :avatar_key, :newsletter_subscription, :about, :goal, :birthday, :travel_distance, :other_interest, :interest_list, :involvement_list, :concerns_list, :interests, :involvements, :concerns, interests: [], involvements: [], concerns: [], availability: {})
      end

      def update_params
        @update_params ||= params.require(:user).permit(:lang, :first_name, :last_name, :email, :sms_code, :password, :secret, :auth_token, :current_phone, :requested_phone, :avatar_key, :newsletter_subscription, :about, :goal, :birthday, :travel_distance, :interest_list, :involvement_list, :concern_list, :interests, :involvements, :concerns, interests: [], involvements: [], concerns: [], availability: {})
      end

      def user_report_params
        params.require(:user_report).permit(:message, signals: [])
      end

      def address_params
        params.require(:address).permit(:place_name, :latitude, :longitude, :street_address, :google_place_id)
      end

      def following_params
        params.require(:following).permit(:partner_id, :active)
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
