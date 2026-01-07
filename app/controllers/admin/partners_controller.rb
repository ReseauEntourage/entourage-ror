module Admin
  class PartnersController < Admin::BaseController
    layout 'admin_large'

    def index
      @staff_teams = Partner.where(staff: true).order(:name)
      @partners = Partner.where(staff: false).includes(:users).order(:name)
    end

    def new
      @partner = Partner.new
      @partner.staff = params[:staff] unless params[:staff].nil?
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
      @partner = Partner.find(params[:id])
      @admins, @members = @partner.users.order(:last_name, :first_name).partition(&:partner_admin)
      @followers = @partner.followers
    end

    def edit
      @partner = Partner.find(params[:id])
    end

    def update
      @partner = Partner.find(params[:id])

      @partner.assign_attributes(partner_params)

      if @partner.save
        redirect_to [:admin, @partner], notice: 'Association mise à jour'
      else
        render :edit
      end
    end

    def edit_logo
      @partner = Partner.find(params[:id])
      @image = @partner.image_url
      @redirect_url = logo_upload_success_admin_partner_url
      @form = PartnerUploader
    end

    def logo_upload_success
      partner = PartnerUploader.handle_success(params)
      redirect_to [:admin, partner], notice: 'Association mise à jour'
    end

    def destroy
      @partner = Partner.find(params[:id])

      Rails.logger.warn "type=partner.delete partner_id=#{@partner.id} attributes=#{JSON.fast_generate(@partner.attributes)}"
      Rails.logger.warn "type=partner.delete partner_id=#{@partner.id} admins=#{JSON.fast_generate(@partner.users.where(partner_admin: true).pluck(:id))} members=#{JSON.fast_generate(@partner.users.where(partner_admin: false).pluck(:id))}"
      Rails.logger.warn "type=partner.delete partner_id=#{@partner.id} followers=#{JSON.fast_generate(@partner.followings.where(active: true).pluck(:user_id))}"

      success = false
      ApplicationRecord.transaction do
        @partner.destroy!
        @partner.users.update_all(
          partner_id:         User.column_defaults['partner_id'],
          partner_admin:      User.column_defaults['partner_admin'],
          partner_role_title: User.column_defaults['partner_role_title'],
          targeting_profile:  User.column_defaults['targeting_profile'],
          goal:               :offer_help,
        )
        success = true
      end

      if success
        redirect_to admin_partners_path, notice: 'Association supprimée'
      else
        redirect_to [:admin, @partner], error: 'Erreur'
      end
    end

    def change_admin_role
      user = User.find(params[:user_id])
      raise unless user.partner.present?
      user.partner_admin = params[:admin]
      user.save
      redirect_to admin_partner_path(user.partner)
    end

    private

    def partner_params
      params.require(:partner).permit(
        :name, :description, :phone, :address, :website_url, :email,
        :latitude, :longitude,
        :donations_needs, :volunteers_needs,
        :staff
      )
    end
  end
end
