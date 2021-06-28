module Admin
  class SuperAdminController < Admin::BaseController
    PER_PAGE = 50

    layout 'admin_large'

    before_action :authenticate_super_admin!

    def entourage_images
      @entourage_images = EntourageImage.page(params[:page]).per(PER_PAGE).map do |entourage_image|
        ::V1::EntourageImageSerializer.new(entourage_image)
      end
    end

    def outings_images
      @outings = Entourage.where(group_type: :outing).where(%(
        metadata->>'landscape_url' is not null or
        metadata->>'landscape_thumbnail_url' is not null or
        metadata->>'portrait_url' is not null or
        metadata->>'portrait_thumbnail_url' is not null
      )).page(params[:page]).per(PER_PAGE).map do |outing|
        ::V1::EntourageSerializer.new(outing)
      end
    end

    def announcements_images
      @announcements = Announcement.where(%(
        image_url is not null or image_portrait_url is not null
      )).page(params[:page]).per(PER_PAGE).map do |announcement|
        ::V1::AnnouncementSerializer.new(announcement)
      end
    end
  end
end
