module OrganizationAdmin
  class EntouragesController < OrganizationAdmin::BaseController
    def edit
      # by now, no entourage edition for organization admin
      redirect_to organization_admin_path
    end

    def edit_image
      @entourage = Entourage.find(params[:id])
      @form = EntourageImageUploader
    end

    def image_upload_success
      entourage = EntourageImageUploader.handle_success(params)
      redirect_to edit_organization_admin_entourage_path(entourage)
    end

    private

    def entourage_params
      params.require(:entourage).permit(:url)
    end
  end
end
