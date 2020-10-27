module Api
  module V1
    module Entourages
      class UsersController < Api::V1::BaseController
        before_action :set_entourage_or_handle_conversation_uuid, only: [:index]
        before_action :set_entourage, except: [:index]
        before_action :restrict_group_types!, except: [:index]
        before_action :set_join_request, only: [:update, :destroy]
        allow_anonymous_access only: [:index]

        #curl -H "Content-Type: application/json" "http://localhost:3000/api/v1/tours/1017/users.json?token=07ee026192ea722e66feb2340a05e3a8"
        def index
          if params[:context] == 'group_feed' && @entourage.group_type == 'conversation'
            join_requests = []
          else
            join_requests =
              @entourage.join_requests
              .where(status: ["pending", "accepted"])
          end

          if @entourage.id.in?(Onboarding::V1::ENTOURAGES.values) &&
             !current_user_or_anonymous.anonymous?
            if current_user.id != @entourage.user_id
              join_requests = join_requests.unscope(where: :status).where(status: :accepted)
            end
            join_requests = join_requests.map { |r| r.message = nil; r }
          end

          users = User
            .where(id: join_requests.map(&:user_id).uniq)
            .includes(:partner)
            .select(:id, :first_name, :last_name, :avatar_key, :validation_status, :roles, :community, :partner_id, :partner_role_title)

          users = Hash[users.map { |u| [u.id, u] }]

          join_requests.each { |r| r.user = users[r.user_id] }

          render json: join_requests, root: "users", each_serializer: ::V1::JoinRequestSerializer
        end

        #curl -X POST -H "Content-Type: application/json" -d '{"distance": 987.65, "request":{"message": "a join message"}}' "http://localhost:3000/api/v1/entourages/1017/users.json?token=azerty"
        def create
          # first we check if the request is already existing
          join_request = JoinRequest.where(joinable: @entourage, user: current_user).first

          is_onboarding, mp_params = Onboarding::V1.entourage_metadata(@entourage)

          if join_request.present?
           message = params.dig(:request, :message)
            updater = JoinRequestsServices::JoinRequestUpdater.new(join_request: join_request,
                                                                   status: JoinRequest::PENDING_STATUS,
                                                                   message: message,
                                                                   current_user: current_user)

            updater.update do |on|
              on.success do
                mixpanel.track("Requested to join Entourage", mp_params)
                mixpanel.track("Wrote Message in Entourage") if message.present?

                render json: join_request, root: "user", status: 201, serializer: ::V1::JoinRequestSerializer
              end

              on.failure do |join_request|
                render json: {message: 'Could not create entourage participation request', reasons: join_request.errors.full_messages}, status: :bad_request
              end

              on.not_authorised do
                render json: {message: 'Could not create entourage participation request', reasons: join_request.errors.full_messages}, status: :bad_request
              end
            end
           return
          end

          join_request_builder = JoinRequestsServices::JoinRequestBuilder.new(joinable: @entourage, user: current_user, message: params.dig(:request, :message), distance: params[:distance])
          join_request_builder.create do |on|
            on.success do |join_request|
              mixpanel.track("Requested to join Entourage", mp_params)
              mixpanel.track("Wrote Message in Entourage") if message.present?

              render json: join_request, root: "user", status: 201, serializer: ::V1::JoinRequestSerializer
            end

            on.failure do |join_request|
              render json: {message: 'Could not create entourage participation request', reasons: join_request.errors.full_messages}, status: :bad_request
            end
          end
        end

        #curl -X PUT -H "Content-Type: application/json" -d '{"request":{"message": "a join message"}}' "http://localhost:3000/api/v1/entourages/1017/users/123.json?token=azerty"
        #curl -X PUT -H "Content-Type: application/json" -d '{"user":{"status": "accepted"}}' "http://localhost:3000/api/v1/entourages/1017/users/123.json?token=azerty"
        def update
          status = params.dig(:user, :status)
          message = params.dig(:request, :message)
          updater = JoinRequestsServices::JoinRequestUpdater.new(join_request: @join_request,
                                                                 status: status,
                                                                 message: message,
                                                                 current_user: @current_user)

          updater.update do |on|
            on.invalid_status do |status|
              render json: {message: "Invalid status : #{status}"}, status: :bad_request
            end

            on.success do
              if status == JoinRequest::ACCEPTED_STATUS
                mixpanel.track("Accepted Join Request to Entourage")
              elsif message.present?
                mixpanel.track("Wrote Message in Entourage")
              end

              head :no_content
            end

            on.failure do |join_request|
              render json: {message: 'Could not update entourage participation request status', reasons: join_request.errors.full_messages}, status: :bad_request
            end

            on.not_authorised do
              return render json: {message: "You don't have rights to manage users of this entourage"}, status: :unauthorized
            end
          end
        end

        #curl -X DELETE -H "Content-Type: application/json" "http://localhost:3000/api/v1/entourages/454/users/428.json?token=azerty"
        def destroy
          updater = JoinRequestsServices::JoinRequestUpdater.new(join_request: @join_request,
                                                                 status: status,
                                                                 message: nil,
                                                                 current_user: @current_user)

          updater.reject do |on|
            on.success do |join_request|
              render json: join_request, root: "user", status: 200, serializer: ::V1::JoinRequestSerializer
            end

            on.failure do |join_request|
              render json: {message: 'Could not update entourage participation request status', reasons: @join_request.errors.full_messages}, status: :bad_request
            end

            on.not_authorised do
              render json: {message: "You are not accepted in this entourage, you don't have rights to manage users of this entourage"}, status: :unauthorized
            end

            on.remove_author do
              render json: {message: 'Cannot remove the author of the entourage'}, status: :bad_request
            end

            on.quit do
              #JoinRequest was destroyed we return an empty join request
              render json: @join_request, root: "user", status: 200, serializer: ::V1::JoinRequestSerializer
            end
          end
        end

        private
        def set_entourage
          @entourage = Entourage.find_by_id_or_uuid(params[:entourage_id])
        end

        def set_entourage_or_handle_conversation_uuid
          set_entourage and return unless ConversationService.list_uuid?(params[:entourage_id])

          participant_ids = ConversationService.participant_ids_from_list_uuid(params[:entourage_id], current_user: current_user_or_anonymous)
          raise ActiveRecord::RecordNotFound unless participant_ids.include?(current_user.id.to_s)
          hash_uuid = ConversationService.hash_for_participants(participant_ids)
          @entourage =
            Entourage.findable.find_by(uuid_v2: hash_uuid) ||
            ConversationService.build_conversation(participant_ids: participant_ids)
        end

        def restrict_group_types!
          unless ['action', 'outing', 'group', 'neighborhood', 'private_circle'].include?(@entourage.group_type)
            render json: {message: "This operation is not available for groups of type '#{@entourage.group_type}'"}, status: :bad_request
          end
        end

        def set_join_request
          @join_request = JoinRequest.where(joinable: @entourage, user: User.find(params[:id])).first!
        end
      end
    end
  end
end
