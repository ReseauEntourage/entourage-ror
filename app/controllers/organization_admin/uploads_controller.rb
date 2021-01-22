module OrganizationAdmin
  class UploadsController < OrganizationAdmin::BaseController
    def new
      uploader = {
        'entourage_image' => EntourageImageUploader
      }[params[:uploader]]

      raise if uploader.nil?

      render json: uploader.form(params)
    end
  end
end
