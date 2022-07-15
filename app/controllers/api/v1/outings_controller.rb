module Api
  module V1
    class OutingsController < Api::V1::BaseController
      before_action :set_outing, only: [:show, :siblings, :update, :batch_update, :duplicate]
      before_action :authorised?, only: [:update, :batch_update]
      before_action :allowed_duplicate?, only: [:duplicate]

      after_action :set_last_message_read, only: [:show]

      def index
        render json: OutingsServices::Finder.new(current_user, index_params).find_all.page(page).per(per), root: :outings, each_serializer: ::V1::OutingSerializer, scope: {
          user: current_user
        }
      end

      def create
        EntourageServices::OutingBuilder.new(params: outing_params, user: current_user).create do |on|
          on.success do |outing|
            render json: outing, root: :outing, status: 201, serializer: ::V1::OutingSerializer, scope: { user: current_user }
          end

          on.failure do |outing|
            render json: { message: 'Could not create outing', reasons: outing.errors.full_messages }, status: 400
          end
        end
      end

      def update
        errors = nil

        ApplicationRecord.transaction do
          unless EntourageServices::OutingBuilder.update_recurrency(outing: @outing, params: outing_recurrency_params)
            errors = @outing.errors.full_messages and raise ActiveRecord::Rollback
          end

          EntourageServices::EntourageBuilder.new(params: outing_params, user: current_user).update(entourage: @outing) do |on|
            on.failure do |outing|
              errors = outing.errors.full_messages and raise ActiveRecord::Rollback
            end
          end
        end

        if errors.present?
          render json: { message: 'Could not update outing', reasons: errors }, status: 400
        else
          render json: @outing.reload, status: 200, serializer: ::V1::OutingSerializer, scope: { user: current_user }
        end
      end

      def batch_update
        @outings = @outing.future_siblings

        errors = nil

        ApplicationRecord.transaction do
          unless EntourageServices::OutingBuilder.batch_update_dates(outing: @outing, params: outing_date_params)
            errors = @outing.errors.full_messages and raise ActiveRecord::Rollback
          end

          @outings.each do |outing|
            EntourageServices::EntourageBuilder.new(params: outing_no_date_params, user: current_user).update(entourage: outing) do |on|
              on.failure do |outing|
                errors = outing.errors.full_messages and raise ActiveRecord::Rollback
              end
            end
          end
        end

        if errors.present?
          render json: { message: 'Could not update outing', reasons: errors }, status: 400
        else
          render json: @outings, status: 200, each_serializer: ::V1::OutingSerializer, scope: { user: current_user }
        end
      end

      def show
        render json: @outing, serializer: ::V1::OutingHomeSerializer, scope: { user: current_user }
      end

      def siblings
        render json: @outing.siblings.page(page).per(per), root: :outings, each_serializer: ::V1::OutingSerializer, scope: {
          user: current_user
        }
      end

      def duplicate
        duplicate = @outing.dup

        if duplicate.save
          render json: duplicate, serializer: ::V1::OutingSerializer, scope: { user: current_user }
        else
          render json: { message: 'Could not duplicate outing', reasons: duplicate.errors.full_messages }, status: 400
        end
      end

      def report
        if report_params[:category].blank?
          render json: {
            code: 'CANNOT_REPORT_OUTING',
            message: 'category is required'
          }, status: :bad_request and return
        end

        SlackServices::SignalOuting.new(
          outing: @outing,
          reporting_user: current_user,
          category: report_params[:category],
          message: report_params[:message]
        ).notify

        head :created
      end

      private

      def set_outing
        @outing = Outing.find(params[:id])
      end

      def index_params
        params.permit(:latitude, :longitude, :travel_distance, :page, :per)
      end

      def outing_params
        params.require(:outing).permit(:status, :title, :description, :event_url, :latitude, :longitude, :other_interest, :online, :recurrency, :entourage_image_id, { metadata: [
          :starts_at,
          :ends_at,
          :place_name,
          :street_address,
          :google_place_id,
          :place_limit
        ] }, neighborhood_ids: [],
          interests: []
        )
      end

      def outing_date_params
        params.require(:outing).permit({ metadata: [:starts_at, :ends_at] })
      end

      def outing_no_date_params
        params.require(:outing).permit(:status, :title, :description, :event_url, :latitude, :longitude, :other_interest, :online, :recurrency, :entourage_image_id, { metadata: [
          :place_name,
          :street_address,
          :google_place_id,
          :place_limit
        ] }, neighborhood_ids: [],
          interests: []
        )
      end

      def outing_recurrency_params
        params.require(:outing).permit(:recurrency)
      end

      def report_params
        params.require(:report).permit(:category, :message)
      end

      def join_request
        @join_request ||= JoinRequest.where(joinable: @outing, user: current_user, status: :accepted).first
      end

      def set_last_message_read
        return unless join_request

        join_request.update(last_message_read: Time.now)
      end

      def page
        params[:page] || 1
      end

      def per
        params[:per] || 25
      end

      def authorised?
        unless @outing.user == current_user
          render json: { message: 'unauthorized user' }, status: :unauthorized
        end
      end

      def allowed_duplicate?
        unless current_user == Outing.find(params[:id]).user
          render json: { message: 'unauthorized user' }, status: :unauthorized
        end

        unless Outing.find(params[:id]).recurrence.present?
          render json: { message: 'no recurrency settings' }, status: :unauthorized
        end
      end
    end
  end
end
