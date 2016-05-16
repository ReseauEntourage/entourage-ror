module Api
  module V1
    class EntouragesController < Api::V1::BaseController
      before_action :set_entourage, only: [:show, :update]

      def index
        finder = EntourageServices::EntourageFinder.new(user: current_user,
                                                        status: params[:status],
                                                        type: params[:type],
                                                        latitude: params[:latitude],
                                                        longitude: params[:longitude],
                                                        distance: params[:distance],
                                                        page: params[:page],
                                                        per: per)
        render json: finder.entourages, each_serializer: ::V1::EntourageSerializer
      end

      def show
        render json: @entourage, serializer: ::V1::EntourageSerializer
      end

      def create
        entourage_builder = EntourageServices::EntourageBuilder.new(params: entourage_params, user: current_user)
        entourage_builder.create do |on|
          on.success do |entourage|
            render json: entourage, status: 201, serializer: ::V1::EntourageSerializer
          end

          on.failure do |entourage|
            render json: {message: 'Could not create entourage', reasons: entourage.errors.full_messages}, status: 400
          end
        end
      end

      def update
        return render json: {message: 'unauthorized'}, status: :unauthorized if @entourage.user != current_user

        if @entourage.update(entourage_params)
          render json: @entourage, status: 201, serializer: ::V1::EntourageSerializer
        else
          render json: {message: 'Could not update entourage', reasons: @entourage.errors.full_messages}, status: 400
        end
      end

      private

      def entourage_params
        params.require(:entourage).permit({location: [:longitude, :latitude]}, :title, :entourage_type, :status)
      end

      def set_entourage
        @entourage = Entourage.find(params[:id])
      end
    end
  end
end