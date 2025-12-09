module Api
  module V1
    class OutingsController < Api::V1::BaseController
      before_action :set_outing, only: [:show, :siblings, :update, :batch_update, :cancel, :destroy, :duplicate, :report]
      before_action :authorised?, only: [:update, :batch_update, :cancel, :destroy]
      before_action :allowed_duplicate?, only: [:duplicate]

      after_action :set_last_message_read, only: [:show]

      def index
        outings = OutingsServices::Finder.new(current_user, index_params)
          .find_all
          .includes(:translation, :user, :interests)
          .page(page)
          .per(per)

        # manual preloads
        outings.tap do |outing|
          ::Preloaders::Outing.preload_images(outing, scope: ImageResizeAction.with_size(:medium))
        end

        outings.tap do |outing|
          ::Preloaders::Outing.preload_member_ids(outing, scope: JoinRequest.accepted)
        end

        render json: outings, root: :outings, each_serializer: ::V1::Outings::IndexSerializer, scope: {
            user: current_user,
            latitude: latitude,
            longitude: longitude
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

        unless EntourageServices::OutingBuilder.update_recurrency(outing: @outing, params: outing_recurrency_params)
          errors = @outing.errors.full_messages
        end

        unless errors.present?
          EntourageServices::EntourageBuilder.new(params: outing_params, user: current_user).update(entourage: @outing) do |on|
            on.failure do |outing|
              errors = outing.errors.full_messages
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
        render json: @outing, serializer: ::V1::OutingHomeSerializer, scope: {
          user: current_user,
          latitude: latitude,
          longitude: longitude
        }
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
        if report_params[:signals].blank?
          render json: {
            code: 'CANNOT_REPORT_OUTING',
            message: 'signals is required'
          }, status: :bad_request and return
        end

        SlackServices::SignalOuting.new(
          outing: @outing,
          reporting_user: current_user,
          signals: report_params[:signals],
          message: report_params[:message]
        ).notify

        head :created
      end

      def cancel
        if EntourageServices::EntourageBuilder.cancel(entourage: @outing, params: cancel_params.to_h)
          render json: @outing, serializer: ::V1::OutingSerializer, scope: { user: current_user }
        else
          render json: { message: 'Could not cancel outing', reasons: @outing.errors.full_messages.to_sentence }, status: 400
        end
      end

      def destroy
        if EntourageServices::EntourageBuilder.close(entourage: @outing)
          render json: @outing, serializer: ::V1::OutingSerializer, scope: { user: current_user }
        else
          render json: { message: 'Could not close outing', reasons: @outing.errors.full_messages.to_sentence }, status: 400
        end
      end

      def smalltalk
        if @outing = Outing.future_or_ongoing.where("title ilike '\%papotage\%'").find_by(online: true)
          render json: @outing, serializer: ::V1::OutingHomeSerializer, scope: { user: current_user }
        else
          render json: { message: 'Could not find outing' }, status: 400
        end
      end

      def count
        outings = OutingsServices::Finder.new(current_user, index_params).find_all

        render json: { count: outings.count }
      end

      def week_average
        from = params[:from].present? ? Time.parse(params[:from]) : 1.year.ago
        to = params[:to].present? ? Time.parse(params[:to]) : Time.now

        average = OutingsServices::Finder.new(current_user, index_params)
          .find_week_average_between(from, to)

        render json: { average: average.round(2) }
      end

      private

      def set_outing
        @outing = Outing.find_by_id_through_context(params[:id], params)

        render json: { message: 'Could not find outing' }, status: 400 unless @outing.present?
      end

      def index_params
        params.permit(:q, :latitude, :longitude, :travel_distance, :within_days, :page, :per, :interest_list, interests: [])
      end

      def outing_params
        permitted_attributes = [
          :status, :title, :description, :event_url, :latitude, :longitude,
          :other_interest, :online, :entourage_image_id,
          { metadata: [
            :starts_at, :ends_at, :place_name, :street_address,
            :google_place_id, :place_limit
          ] },
          neighborhood_ids: [],
          interests: []
        ]

        permitted_attributes << :recurrency if current_user.ambassador? || current_user.association?

        params.require(:outing).permit(permitted_attributes)
      end

      def cancel_params
        params.permit(outing: [:cancellation_message])
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
        params.require(:report).permit(:message, signals: [])
      end

      def join_request
        @join_request ||= JoinRequest.where(joinable: @outing, user: current_user, status: :accepted).first
      end

      def set_last_message_read
        return unless join_request

        join_request.set_chat_messages_as_read
      end

      def page
        params[:page] || 1
      end

      def latitude
        params[:latitude] || current_user.latitude
      end

      def longitude
        params[:longitude] || current_user.longitude
      end

      def authorised?
        unless @outing.can_be_managed_by?(current_user)
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
