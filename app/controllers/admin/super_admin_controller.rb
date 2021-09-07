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

    def jobs_metrics
      @history = JobMetricService.history(7)

      @jober = {
        retries: JobMetricService.retries,
        deads: JobMetricService.deads,
        schedules: JobMetricService.schedules,
        processes: JobMetricService.processes,
        workers: JobMetricService.workers,
        queues: JobMetricService.queues,
        stats: [JobMetricService.stats],
        history_failed: @history[:failed].map{ |v| { day: v.first, count: v.last } },
        history_processed: @history[:processed].map{ |v| { day: v.first, count: v.last } },
      }
    end

    def jobs_crons
    end

    def force_close_tours
      JobCronService.force_close_tours

      redirect_to admin_super_admin_jobs_metrics_path, flash: {
        success: "Un job a été créé pour fermer les maraudes en cours"
      }
    end

    def unread_reminder_email
      JobCronService.unread_reminder_email

      redirect_to admin_super_admin_jobs_metrics_path, flash: {
        success: "Un job a été créé pour envoyer un mail de rappel des messages non lus"
      }
    end

    def onboarding_sequence_send_welcome_messages
      JobCronService.onboarding_sequence_send_welcome_messages

      redirect_to admin_super_admin_jobs_metrics_path, flash: {
        success: "Un job a été créé pour envoyer les messages de bienvenue"
      }
    end
  end
end
