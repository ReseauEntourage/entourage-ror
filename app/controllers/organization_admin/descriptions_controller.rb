module OrganizationAdmin
  class DescriptionsController < BaseController
    before_action :ensure_can_edit_description!, except: [:index, :show]

    layout_options active_menu: :description

    def edit
      @partner = current_user.partner
    end

    def update
      partner = current_user.partner
      if partner.update(partner_params)
        flash[:success] = 'Description modifiée !'
        redirect_to edit_organization_admin_description_path
      else
        flash[:error] = partner.errors.full_messages.to_sentence
        redirect_to edit_organization_admin_description_path
      end
    end

    def edit_logo
      @partner = current_user.partner
      @form = PartnerLogoUploader
    end

    def new_logo_upload
      render json: PartnerLogoUploader.form(
        partner_id:   current_user.partner_id,
        redirect_url: logo_upload_success_organization_admin_description_url,
        filetype:     params[:filetype]
      )
    end

    def logo_upload_success
      PartnerLogoUploader.handle_success(params)
      flash[:success] = 'Logo modifié !'
      redirect_to edit_organization_admin_description_path
    end

    private

    def ensure_can_edit_description!
      unless OrganizationAdmin::Permissions.can_edit_description?(current_user)
        render text: "Vous n'avez pas la permission de modifier la description", status: :unauthorized
      end
    end

    def partner_params
      params.require(:partner).permit(
        :name,
        :description, :donations_needs, :volunteers_needs,
        :phone, :address, :website_url, :email,
        :latitude, :longitude
      )
    end
  end
end
