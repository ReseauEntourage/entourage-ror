module Api
  module V0
    class PoisController < Api::V0::BaseController
      attr_writer :member_mailer

      def index
        @categories = Category.all
        @pois = Poi.all
        @pois = @pois.around params[:latitude], params[:longitude], params[:distance] if params[:latitude].present? and params[:longitude].present?
      end

      def create
        @poi = Poi.new(poi_params)
        @poi.validated = false
        if @poi.save
          render "show", status: 201
        else
          render '400', status: 400
        end
      end

      def report
        poi = Poi.find_by(id: params[:id])
        if poi.nil?
          head '404'
        else
          message = params[:message]
          if message.nil?
            render '400', status: 400
          else
            mail = member_mailer.poi_report(poi, @current_user, message).deliver_later
            render json: {message: message}, status: 201
          end
        end
      end

      private

      def poi_params
        params.require(:poi).permit(:name, :latitude, :longitude, :adress, :phone, :website, :email, :audience, :category_id)
      end

      def member_mailer
        @member_mailer ||= MemberMailer
      end
    end
  end
end
