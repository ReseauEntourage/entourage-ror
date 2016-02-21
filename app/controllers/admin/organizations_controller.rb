module Admin
  class OrganizationsController < Admin::BaseController
    before_action :set_organization, only: [:edit, :update]

    def index
      @organizations = Organization.order("name ASC").page(params[:page]).per(25)
    end

    def edit
    end

    def update
    end

    private
    def set_organization
      @organization = Organization.find(params[:id])
    end
  end
end