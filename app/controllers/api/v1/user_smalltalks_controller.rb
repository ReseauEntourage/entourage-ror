module Api
  module V1
    class UserSmalltalksController < Api::V1::BaseController
      before_action :set_user_smalltalk, only: [:show, :current, :update, :match, :destroy, :force_match, :match, :matches, :almost_matches, :matches_by_criteria]
      before_action :ensure_is_creator, only: [:show, :update, :match, :destroy, :force_match, :match, :matches, :almost_matches, :matches_by_criteria]

      def index
        render json: UserSmalltalk
          .includes(:user)
          .with_accessible_smalltalks_for_user(current_user)
          .or(UserSmalltalk.where(user: current_user, smalltalk_id: nil))
          .page(page)
          .per(per), root: :user_smalltalks, each_serializer: ::V1::UserSmalltalkSerializer
      end

      def show
        render json: @user_smalltalk, serializer: ::V1::UserSmalltalkSerializer
      end

      def current
        return render json: { error: "UserSmalltalk not found" }, status: :not_found unless @user_smalltalk.present?

        redirect_to user_smalltalk_path(@user_smalltalk)
      end

      def create
        @user_smalltalk = UserSmalltalk.new(user_smalltalk_params)
        @user_smalltalk.user = current_user

        if @user_smalltalk.save
          render json: @user_smalltalk, status: 201, serializer: ::V1::UserSmalltalkSerializer
        else
          render json: { message: "Could not create UserSmalltalk", reasons: @user_smalltalk.errors.full_messages }, status: 400
        end
      end

      def update
        @user_smalltalk.assign_attributes(user_smalltalk_params)

        if @user_smalltalk.save
          render json: @user_smalltalk, status: 200, serializer: ::V1::UserSmalltalkSerializer
        else
          render json: {
            message: 'Could not update user_smalltalk', reasons: @user_smalltalk.errors.full_messages
          }, status: 400
        end
      end

      def force_match
        if @user_smalltalk.force_and_save_match!(params[:smalltalk_id])
          render json: { match: true, smalltalk_id: @user_smalltalk.smalltalk_id }, status: 200
        else
          render json: { match: false, smalltalk_id: nil }, status: 200
        end
      end

      def match
        if @user_smalltalk.find_and_save_match!
          render json: { match: true, smalltalk_id: @user_smalltalk.smalltalk_id }, status: 200
        else
          render json: { match: false, smalltalk_id: nil }, status: 200
        end
      end

      def matches
        render json: @user_smalltalk
          .find_matches
          .includes(:user)
          .page(page)
          .per(per), root: :user_smalltalks, each_serializer: ::V1::UserSmalltalkSerializer
      end

      def almost_matches
        render json: @user_smalltalk
          .find_almost_matches
          .includes(:user)
          .page(page)
          .per(per), root: :user_smalltalks, each_serializer: ::V1::UserSmalltalkSerializer
      end

      def matches_by_criteria
        render json: @user_smalltalk.find_matches_count_by(params[:criteria])
      rescue ArgumentError
        render json: { message: "Excepted criteria should be included in #{UserSmalltalk::CRITERIA.join(', ')}" }
      end

      def destroy
        if @user_smalltalk.update(deleted_at: Time.zone.now)
          render json: @user_smalltalk, root: "user", status: 200, serializer: ::V1::UserSmalltalkSerializer
        else
          render json: {
            message: "Could not delete user_smalltalk", reasons: @user_smalltalk.errors.full_messages
          }, status: :bad_request
        end
      end

      private

      def set_user_smalltalk
        @user_smalltalk = if params[:id].present?
          UserSmalltalk.find_by_id_through_context(params[:id], params)
        else
          UserSmalltalk.not_matched.find_by(user: current_user)
        end

        render json: { message: 'Could not find user_smalltalk' }, status: 400 unless @user_smalltalk.present?
      end

      def ensure_is_creator
        render json: { message: 'unauthorized' }, status: :unauthorized unless @user_smalltalk.user == current_user
      end

      def user_smalltalk_params
        params.require(:user_smalltalk).permit(:match_format, :match_locality, :match_gender)
      end

      def page
        params[:page] || 1
      end
    end
  end
end
