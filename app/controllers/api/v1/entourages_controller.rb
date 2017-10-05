module Api
  module V1
    class EntouragesController < Api::V1::BaseController
      before_action :set_entourage, only: [:show, :update, :read]

      def index
        finder = EntourageServices::EntourageFinder.new(user: current_user,
                                                        status: params[:status],
                                                        type: params[:type],
                                                        latitude: params[:latitude],
                                                        longitude: params[:longitude],
                                                        distance: params[:distance],
                                                        page: params[:page],
                                                        per: per,
                                                        atd: params[:atd])
        render json: finder.entourages, each_serializer: ::V1::EntourageSerializer, scope: {user: current_user}
      end

      #curl -H "Content-Type: application/json" "http://localhost:3000/api/v1/entourages/951.json?token=e4fdc865bc7a91c34daea849e7d73349&distance=123.45&feed_rank=2"
      def show
        EntourageServices::EntourageDisplayService.new(entourage: @entourage, user: current_user, params: params).view
        render json: @entourage, serializer: ::V1::EntourageSerializer, scope: {user: current_user}
      end

      #curl -H "Content-Type: application/json" -X POST -d '{"entourage": {"title": "entourage1", "entourage_type": "ask_for_help", "description": "lorem ipsum", "location": {"latitude": 37.4224764, "longitude": -122.0842499}}, "token": "azerty"}' "http://localhost:3000/api/v1/entourages.json"
      def create
        entourage_builder = EntourageServices::EntourageBuilder.new(params: entourage_params, user: current_user)
        entourage_builder.create do |on|
          on.success do |entourage|
            render json: entourage, status: 201, serializer: ::V1::EntourageSerializer, scope: {user: current_user}
          end

          on.failure do |entourage|
            render json: {message: 'Could not create entourage', reasons: entourage.errors.full_messages}, status: 400
          end
        end
      end

      def update
        return render json: {message: 'unauthorized'}, status: :unauthorized if @entourage.user != current_user

        entourage_builder = EntourageServices::EntourageBuilder.new(params: entourage_params, user: current_user)
        entourage_builder.update(entourage: @entourage) do |on|
          on.success do |entourage|
            render json: @entourage, status: 200, serializer: ::V1::EntourageSerializer, scope: {user: current_user}
          end

          on.failure do |entourage|
            render json: {message: 'Could not update entourage', reasons: @entourage.errors.full_messages}, status: 400
          end
        end
      end


      #curl -H "Content-Type: application/json" -X PUT "http://localhost:3000/api/v1/entourages/1184/read.json?token=azerty"
      def read
        @entourage.join_requests
                  .accepted
                  .where(user: current_user)
                  .update_all(last_message_read: DateTime.now)
        head :no_content
      end

      private

      def entourage_params
        params.require(:entourage).permit({location: [:longitude, :latitude]}, :title, :entourage_type, :display_category, :status, :description, :category)
      end

      def set_entourage
        @entourage = Entourage.visible.find(params[:id])
      end
    end
  end
end
