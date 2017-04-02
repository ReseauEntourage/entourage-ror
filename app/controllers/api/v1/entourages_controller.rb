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
                                                        per: per)
        render json: finder.entourages, each_serializer: ::V1::EntourageSerializer, scope: {user: current_user}
      end

      def show
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

      def read
        @entourage.join_requests
                  .accepted
                  .where(user: current_user)
                  .update_all(last_message_read: DateTime.now)
        head :no_content
      end

      private

      def entourage_params
        params.require(:entourage).permit({location: [:longitude, :latitude]}, :title, :entourage_type, :status, :description)
      end

      def set_entourage
        @entourage = Entourage.find(params[:id])
      end
    end
  end
end