module Admin
  class UploadsController < Admin::BaseController
    layout 'admin_large'

    def new
      uploader = {
        'partner_logo' => PartnerLogoUploader,
        'announcement_image' => AnnouncementImageUploader,
        'entourage_image' => EntourageImageUploader,
        'entourage_image_landscape_uploader' => EntourageImageLandscapeUploader,
        'entourage_image_portrait_uploader' => EntourageImagePortraitUploader
      }[params[:uploader]]

      raise if uploader.nil?

      render json: uploader.form(upload_params.to_h)
    end

    private

    def upload_params
      params.permit([:uploader, :redirect_url, :filetype, :controller, :action,
        :entourage_image_id,
        :announcement_id,
        :entourage_id,
        :partner_id
      ])
    end
  end
end
