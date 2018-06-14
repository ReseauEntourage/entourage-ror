module Api
  module V1
    class ActionZonesController < Api::V1::BaseController
      skip_before_filter :authenticate_user!, only: [:confirm]

      def confirm
        user_id = UserServices::EncodedId.decode(params[:user_id])

        begin
          ActionZone.create!(
            user_id: user_id,
            country: 'FR',
            postal_code: params[:postal_code]
          )
        rescue ActiveRecord::RecordNotUnique
        end

        render layout: false
      end
    end
  end
end
