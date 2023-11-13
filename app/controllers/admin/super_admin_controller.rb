module Admin
  class SuperAdminController < Admin::BaseController
    PER_PAGE = 50

    layout 'admin_large'

    before_action :authenticate_super_admin!

    def entourage_images
      @paginated = EntourageImage.page(params[:page]).per(PER_PAGE)

      @entourage_images = @paginated.map do |entourage_image|
        ::V1::EntourageImageSerializer.new(entourage_image).object
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
        ::V1::EntourageSerializer.new(outing).object
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
        }).object
      end
    end

    def soliguide
      @pois = []
      @poi = nil

      params[:latitude] ||= PoiServices::Soliguide::PARIS[:latitude]
      params[:longitude] ||= PoiServices::Soliguide::PARIS[:longitude]

      soliguide = PoiServices::Soliguide.new(soliguide_params)
      @pois = PoiServices::SoliguideIndex.post(soliguide.query_params)
    end

    def soliguide_show
      @poi = PoiServices::SoliguideShow.get(params[:id][1..], current_user.lang)
    end

    def jobs_crons
    end

    def force_close_tours
      JobCronService.force_close_tours

      redirect_to sidekiq_web_path, flash: {
        success: "Un job a été créé pour fermer les maraudes en cours"
      }
    end

    def unread_reminder_email
      JobCronService.unread_reminder_email

      redirect_to sidekiq_web_path, flash: {
        success: "Un job a été créé pour envoyer un mail de rappel des messages non lus"
      }
    end

    def onboarding_sequence_send_welcome_messages
      JobCronService.onboarding_sequence_send_welcome_messages

      redirect_to sidekiq_web_path, flash: {
        success: "Un job a été créé pour envoyer les messages de bienvenue"
      }
    end

    def inapp_notifications
      @params = params.permit(:context)
      @context = params[:context] || :all

      @inapp_notifications = InappNotification.unscoped
        .select("count(*) as count, min(created_at) as min_created_at, instance, context, title")
        .with_context(params[:context])
        .group(:instance, :instance_id, :context, :title)
        .order("min_created_at desc")
        .page(params[:page]).per(PER_PAGE)
    end

    private

    def soliguide_params
      params.permit(:limit, :latitude, :longitude, :distance, :category_ids, :query)
    end
  end
end
