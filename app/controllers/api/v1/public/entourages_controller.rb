module Api
  module V1
    module Public
      class EntouragesController < Api::V1::Public::BaseController
        before_action :set_entourage, only: [:show]

        def show
          if @entourage
            render json: public_entourage_json, status: 200
          else
            render json: { message: "Could not found Entourage" }, status: 404
          end
        end

        private

        def set_entourage
          @entourage = Entourage.visible.find_by(uuid: params[:uuid])
        end

        def public_entourage_json
          { uuid: @entourage.uuid,
            title: @entourage.title,
            description: @entourage.description,
            created_at: I18n.l(@entourage.created_at, format: "%e %B"),
            author: {
                display_name: @entourage.user.first_name,
                avatar_url: UserServices::Avatar.new(user: @entourage.user).thumbnail_url
            }
          }.to_json
        end
      end
    end
  end
end
