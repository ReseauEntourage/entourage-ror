module Api
  module V1
    module Tours
      class ChatMessagesController < Api::V1::Entourages::ChatMessagesController

        private
        def set_entourage
          @entourage = Tour.find(params[:tour_id])
        end
      end
    end
  end
end