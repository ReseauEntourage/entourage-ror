module Admin
  class UploadsController < Admin::BaseController
    layout 'admin_large'

    def new
      uploader = {
        'partner_logo' => PartnerLogoUploader
      }[params[:uploader]]

      raise if uploader.nil?

      render json: uploader.form(params)
    end
  end
end
