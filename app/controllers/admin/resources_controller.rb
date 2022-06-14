module Admin
  class ResourcesController < Admin::BaseController
    layout 'admin_large'

    before_action :set_resource, only: [:edit, :update, :destroy]

    def index
      @resources = Resource.page(page).per(per)
    end

    def new
      @resource = Resource.new
    end

    def create
      @resource = Resource.new(resource_params)

      if @resource.save
        redirect_to admin_resources_path, notice: "Le contenu pédagogique a bien été créé"
      else
        render :new
      end
    end

    def edit
    end

    def update
      @resource.assign_attributes(resource_params)

      if @resource.save
        redirect_to edit_admin_resource_path(@resource), notice: "Contenu pédagogique mis à jour"
      else
        render :edit
      end
    end

    def destroy
    end

    private

    def set_resource
      @resource = Resource.find(params[:id])
    end

    def resource_params
      params.require(:resource).permit(
        :name,
        :category,
        :description,
        :url,
        :is_video,
        :duration
      )
    end
  end
end
