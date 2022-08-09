module Admin
  class ResourcesController < Admin::BaseController
    layout 'admin_large'

    before_action :set_resource, only: [:edit, :update, :destroy, :edit_image, :update_image]

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

    def edit_image
      @resource_images = ResourceImage.all
    end

    def update_image
      @resource.assign_attributes(resource_params)

      if @resource.save
        redirect_to edit_admin_resource_path(@resource)
      else
        @resource_images = ResourceImage.all
        render :edit_image
      end
    end

    def destroy
      if @resource.update_attribute(:status, :deleted)
        redirect_to admin_resources_path, notice: "Le contenu pédagogique a bien été supprimé"
      else
        redirect_to edit_admin_resource_path(@resource), error: "Le contenu pédagogique n'a pas pu être supprimé"
      end
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
        :duration,
        :resource_image_id,
      )
    end
  end
end
