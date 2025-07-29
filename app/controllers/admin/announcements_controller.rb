module Admin
  class AnnouncementsController < Admin::BaseController
    layout 'admin_large'

    def index
      @params = params.permit([:status, :area, :user_goal]).to_h
      @status = params[:status].presence&.to_sym
      @status = :active unless @status.in?([:draft, :archived])

      @area = params[:area].presence&.to_sym
      @area = :all unless @area.in?(ModerationArea.all_slugs)

      @user_goal = params[:user_goal].presence&.to_sym
      @user_goal = :all unless @user_goal.in?(UserGoalPresenter.all_slugs(community))

      @announcements = Announcement.where(status: @status)
      @announcements = @announcements.for_areas([@area]) if @area && @area != :all
      @announcements = @announcements.for_user_goal(@user_goal) if @user_goal && @user_goal != :all

      if @status == :active
        @announcements = @announcements.ordered
      else
        @announcements = @announcements.order(id: :desc)
      end
    end

    def new
      @announcement = Announcement.new

      # pre-fill targeting
      @announcement.areas = ModerationArea.all_slugs
      @announcement.user_goals = UserGoalPresenter.all_slugs(community)
    end

    def create
      @announcement = Announcement.new(announcement_params)
      if @announcement.save
        redirect_to edit_admin_announcement_path(@announcement)
      else
        render :new
      end
    end

    def edit
      @announcement = Announcement.find(params[:id])
    end

    def update
      @announcement = Announcement.find(params[:id])
      @announcement.assign_attributes(announcement_params)

      if params.key?(:publish)
        @announcement.status = :active
      elsif params.key?(:archive)
        @announcement.status = :archived
      end

      if @announcement.save
        redirect_to edit_admin_announcement_path(@announcement)
      else
        @announcement.status = @announcement.status_was
        render :edit
      end
    end

    def edit_image
      @announcement = Announcement.find(params[:id])
      @image = @announcement.image_url
      @redirect_url = image_upload_success_admin_announcement_url
      @form = AnnouncementImageUploader # @dead-code?
    end

    def edit_image_portrait
      @announcement = Announcement.find(params[:id])
      @image = @announcement.image_portrait_url
      @redirect_url = image_portrait_upload_success_admin_announcement_url
      @form = AnnouncementImagePortraitUploader # @dead-code?
      render :edit_image
    end

    def image_upload_success
      announcement = AnnouncementImageUploader.handle_success(params)
      redirect_to edit_admin_announcement_path(announcement)
    end

    def image_portrait_upload_success
      announcement = AnnouncementImagePortraitUploader.handle_success(params)
      redirect_to edit_admin_announcement_path(announcement)
    end

    def reorder
      ordered_ids = (params[:ordered_ids] || '').to_s.split(',').map(&:to_i).uniq.reject(&:zero?)

      ApplicationRecord.transaction do
        Announcement
          .active.where(id: ordered_ids)
          .sort_by { |a| ordered_ids.index(a.id) }
          .each.with_index(1) { |a, i| a.update_column(:position, i) }
      end

      redirect_to admin_announcements_path
    end

    private

    def announcement_params
      params.require(:announcement).permit(
        :title, :icon, :body, :action, :url, :webapp_url, :webview, :category, areas: [], user_goals: []
      )
    end
  end
end
