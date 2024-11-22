module Api
  module V1
    class EntouragesController < Api::V1::BaseController
      before_action :set_entourage_or_handle_conversation_uuid, only: [:show]
      before_action :set_entourage, only: [:update, :update_galery, :read, :one_click_update, :report, :dismiss_report_prompt]
      skip_before_action :authenticate_user!, only: [:one_click_update]
      allow_anonymous_access only: [:show]

      def index
        entourages = EntourageServices::EntourageFinder.new(
          user: current_user,
          types: params[:types],
          latitude: params[:latitude],
          longitude: params[:longitude],
          distance: params[:distance],
          page: params[:page],
          per: per,
          show_past_events: params[:show_past_events],
          time_range: params[:time_range],
          before: params[:before],
          partners_only: params[:partners_only],
          status: params[:status]
        ).entourages

        render json: entourages, root: :entourages, each_serializer: ::V1::EntourageSerializer, scope: {
          user: current_user
        }
      end

      def search
        entourages = EntourageServices::EntourageFinder.new(
          user: current_user,
          search: params[:q],
          types: params[:types],
          latitude: params[:latitude],
          longitude: params[:longitude],
          page: params[:page],
          per: per,
          time_range: 31*24
        ).entourages

        render json: entourages, root: :entourages, each_serializer: ::V1::EntourageSerializer, scope: {
          user: current_user
        }
      end

      def joined
        entourages = EntourageServices::EntourageFinder.new(
          user: current_user,
          page: params[:page],
          per: per,
          time_range: 24 * 365,
          show_my_entourages_only: true
        ).entourages

        render json: entourages, root: :entourages, each_serializer: ::V1::EntourageSerializer, scope: {
          user: current_user
        }
      end

      def owned
        entourages = Entourage
          .where(status: :open)
          .where(group_type: [:action])
          .where("entourages.created_at > ?", 1.year.ago)
          .where(user: current_user)
          .order(updated_at: :desc)

        render json: entourages, root: :entourages, each_serializer: ::V1::EntourageSerializer, scope: {
          user: current_user
        }
      end

      def invited
        entourages = EntourageServices::EntourageFinder.new(
          user: current_user,
          page: params[:page],
          per: per,
          time_range: 24 * 365,
          invitee: current_user
        ).entourages

        render json: entourages, root: :entourages, each_serializer: ::V1::EntourageSerializer, scope: {
          user: current_user
        }
      end

      #curl -H "Content-Type: application/json" "http://localhost:3000/api/v1/entourages/951.json?token=e4fdc865bc7a91c34daea849e7d73349&distance=123.45&feed_rank=2"
      def show
        ensure_permission! :can_read_public_content?

        is_onboarding, mp_params = Onboarding::V1.entourage_metadata(@entourage)
        include_last_message = params[:include_last_message] == 'true'
        render json: @entourage, serializer: ::V1::EntourageSerializer, scope: {user: current_user_or_anonymous, include_last_message: include_last_message}
      end

      #curl -H "Content-Type: application/json" -X POST -d '{"entourage": {"title": "entourage1", "entourage_type": "ask_for_help", "description": "lorem ipsum", "location": {"latitude": 37.4224764, "longitude": -122.0842499}}, "token": "azerty"}' "http://localhost:3000/api/v1/entourages.json"
      def create
        entourage_builder = EntourageServices::EntourageBuilder.new(params: entourage_params, user: current_user)
        entourage_builder.create do |on|
          on.success do |entourage|
            render json: entourage, root: :entourage, status: 201, serializer: ::V1::EntourageSerializer, scope: {user: current_user}
          end

          on.failure do |entourage|
            render json: {message: 'Could not create entourage', reasons: entourage.errors.full_messages}, status: 400
          end
        end
      end

      def update
        return render json: {message: 'unauthorized'}, status: :unauthorized if @entourage.user != current_user

        unless ['action', 'outing', 'group'].include?(@entourage.group_type)
          return render json: {message: "This operation is not available for groups of type '#{@entourage.group_type}'"}, status: :bad_request
        end

        entourage_builder = EntourageServices::EntourageBuilder.new(params: entourage_params, user: current_user)
        entourage_builder.update(entourage: @entourage) do |on|
          on.success do |entourage|
            render json: @entourage, root: :entourage, status: 200, serializer: ::V1::EntourageSerializer, scope: {user: current_user}
          end

          on.failure do |entourage|
            render json: {message: 'Could not update entourage', reasons: @entourage.errors.full_messages}, status: 400
          end
        end
      end

      #curl -H "Content-Type: application/json" -X PUT "http://localhost:3000/api/v1/entourages/1184/read.json?token=azerty"
      def read
        join_request = @entourage.join_requests
          .accepted
          .where(user: current_user)
          .first
          &.set_chat_messages_as_read

        head :no_content
      end

      def one_click_update
        @success = false

        if SignatureService.validate(@entourage.id, params[:signature])
          service = EntourageServices::EntourageBuilder.new(
            params: {status: :closed, outcome: {success: true}},
            user: @entourage.user
          )
          service.update(entourage: @entourage) do |on|
            on.success { @success = true }
          end
        end

        render layout: 'landing'
      end

      def report
        message = entourage_report_params[:message]
        if message.blank?
          render json: { code: 'CANNOT_REPORT_ENTOURAGE' }, status: :bad_request
          return
        end

        reporting_user = current_user_or_anonymous
        reporting_user = reporting_user.token if reporting_user.anonymous?

        if @entourage.conversation?
          SlackServices::SignalConversation.new(
            conversation: @entourage,
            reporting_user: current_user_or_anonymous,
            signals: ["n/a"],
            message: message
          ).notify
        else
          SlackServices::SignalGroup.new(
            reported_group: @entourage,
            reporting_user: reporting_user,
            message:        message
          ).notify

          UserHistory.create({
            user_id: @entourage.user_id,
            updater_id: reporting_user.id,
            kind: 'signal-action',
            metadata: {
              message: message,
              entourage_id: @entourage.id
            }
          })
        end

        head :created
      end

      def dismiss_report_prompt
        @entourage.join_requests
                  .accepted
                  .where(user: current_user)
                  .update_all(report_prompt_status: 'dismissed')
        head :no_content
      end

      private

      def entourage_params
        metadata_keys = params.dig(:entourage, :metadata).try(:keys) || []
        params.require(:entourage).permit(:group_type, {location: [:longitude, :latitude]}, :title, :entourage_type, :display_category, :status, :description, :category, :public, {outcome: [:success]}, {metadata: metadata_keys}, :recipient_consent_obtained)
      end

      def entourage_report_params
        params.require(:entourage_report).permit(:message)
      end

      def set_entourage
        @entourage = Entourage.findable_by_id_or_uuid(params[:id])
      end

      def set_entourage_or_handle_conversation_uuid
        set_entourage and return unless ConversationService.list_uuid?(params[:id])

        if current_user_or_anonymous.anonymous?
          return render json: {
            message: "Anonymous user can't access this resource.",
            code: 'ANONYMOUS_USER_AUTHENTICATION_REQUIRED'
          }, status: :unauthorized
        end

        participant_ids = ConversationService.participant_ids_from_list_uuid(params[:id], current_user: current_user)

        raise ActiveRecord::RecordNotFound unless participant_ids.include?(current_user.id.to_s)

        hash_uuid = ConversationService.hash_for_participants(participant_ids)

        @entourage = Entourage.findable.find_by(uuid_v2: hash_uuid) ||
          ConversationService.build_conversation(participant_ids: participant_ids, creator_id: current_user.id)
      end

      def ensure_permission! permission
        has_permission = GroupAccessService.send(
          permission,
          user: current_user_or_anonymous,
          group: @entourage
        )
        raise ActiveRecord::RecordNotFound unless has_permission
      end
    end
  end
end
