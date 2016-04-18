module Api
  module V1
    module Entourages
      class InvitationsController
        before_action :set_entourage

        def create

        end

        private

        def set_entourage
          @entourage = Entourage.find(params[:entourage_id])
        end
      end
    end
  end
end