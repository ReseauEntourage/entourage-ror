module Admin
  class PartnersController < Admin::BaseController
    layout 'admin_large'

    def index
      @partners = Partner.all
    end

    def new
      @partner = Partner.new
    end

    def create
      @partner = Partner.new(partner_params)

      if @partner.save
        redirect_to [:admin, @partner]
      else
        render :new
      end
    end

    def show
      redirect_to edit_admin_partner_path(params[:id])
    end

    def edit
      @partner = Partner.find(params[:id])
    end

    def update
      @partner = Partner.find(params[:id])

      @partner.assign_attributes(partner_params)

      if @partner.save
        redirect_to [:admin, @partner], notice: "Association mise à jour"
      else
        render :edit
      end
    end

    def edit_logo
      @partner = Partner.find(params[:id])
      @form = PartnerLogoUploader
    end

    def logo_upload_success
      partner = PartnerLogoUploader.handle_success(params)
      redirect_to [:admin, partner], notice: "Association mise à jour"
    end

    def destroy
      @partner = Partner.find(params[:id])

      if @partner.destroy
        redirect_to admin_partners_path, notice: "Association supprimée"
      else
        redirect_to [:admin, @partner], error: "Erreur"
      end
    end

    private

    def partner_params
      params.require(:partner).permit(
        :name, :description, :phone, :address, :website_url, :email
      )
    end
  end
end
