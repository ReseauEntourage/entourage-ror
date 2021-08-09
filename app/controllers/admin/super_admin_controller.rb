module Admin
  class SuperAdminController < Admin::BaseController
    PER_PAGE = 50

    layout 'admin_large'

    before_action :authenticate_super_admin!

    def entourage_images
      @paginated = EntourageImage.page(params[:page]).per(PER_PAGE)

      @entourage_images = @paginated.map do |entourage_image|
        ::V1::EntourageImageSerializer.new(entourage_image)
      end
    end

    def outings_images
      @paginated = Entourage.where(group_type: :outing).where(%(
        metadata->>'landscape_url' is not null or
        metadata->>'landscape_thumbnail_url' is not null or
        metadata->>'portrait_url' is not null or
        metadata->>'portrait_thumbnail_url' is not null
      )).page(params[:page]).per(PER_PAGE)

      @outings = @paginated.map do |outing|
        ::V1::EntourageSerializer.new(outing)
      end
    end

    def announcements_images
      @paginated = Announcement.where(%(
        image_url is not null or image_portrait_url is not null
      )).order(:status).page(params[:page]).per(PER_PAGE)

      @announcements = @paginated.map do |announcement|
        ::V1::AnnouncementSerializer.new(announcement, scope: {
          user: current_user,
          base_url: request.base_url
        })
      end
    end

    def jobs
      @jober = {
        retries: JobService.retries,
        deads: JobService.deads,
        schedules: JobService.schedules,
        processes: JobService.processes,
        workers: JobService.workers,
      }

      @stats = JobService.stats
      @history = JobService.history(2)
    end
  end
end
