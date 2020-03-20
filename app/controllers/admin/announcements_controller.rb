module Admin
  class AnnouncementsController < Admin::BaseController
    layout 'admin_large'

    def index
      @status = params[:status].presence&.to_sym
      @status = :active unless @status.in?([:draft, :archived])

      @announcements = Announcement.where(status: @status)

      if @status == :active
        @announcements = @announcements.ordered
      else
        @announcements = @announcements.order(id: :desc)
      end
    end

    def new
      @announcement = Announcement.new
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
      @form = AnnouncementImageUploader
    end

    def image_upload_success
      announcement = AnnouncementImageUploader.handle_success(params)
      redirect_to edit_admin_announcement_path(announcement)
    end

    def reorder
      ordered_ids = (params[:ordered_ids] || "").to_s.split(',').map(&:to_i).uniq.reject(&:zero?)

      ActiveRecord::Base.transaction do
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
        :title, :icon, :body, :action, :url, :webview
      )
    end
  end
end
