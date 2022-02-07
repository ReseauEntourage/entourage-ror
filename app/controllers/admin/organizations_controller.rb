module Admin
  class OrganizationsController < Admin::BaseController
    before_action :set_organization, only: [:show, :edit, :update]

    def index
      @q = Organization.ransack(params[:q])
      @organizations = @q.result(distinct: true)
                         .page(params[:page])
                         .per(25)
                         .order("name ASC")
    end

    def show
      @members = @organization.users.order(:last_name, :first_name)
    end

    def edit
    end

    def update
      if @organization.update(organization_params)
        redirect_to admin_organizations_path, notice: "L'association a bien été mise à jour"
      else
        render :edit
      end
    end

    private
    def set_organization
      @organization = Organization.find(params[:id])
    end

    def organization_params
      params.require(:organization).permit(:name, :description, :phone, :address, :logo_url, :test_organization)
    end
  end
end
