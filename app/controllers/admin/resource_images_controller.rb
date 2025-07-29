module Admin
  class ResourceImagesController < Admin::BaseController
    def index
      @resource_images = ResourceImage.order(title: :asc)
    end

    def new
      @resource_image = ResourceImage.new
    end

    def create
      @resource_image = ResourceImage.new(resource_image_params)
      if @resource_image.save
        redirect_to edit_admin_resource_image_path(@resource_image.id)
      else
        render :new
      end
    end

    def edit
      @resource_image = ResourceImage.find(params[:id])
    end

    def update
      @resource_image = ResourceImage.find(params[:id])
      @resource_image.assign_attributes(resource_image_params)

      if @resource_image.save
        redirect_to edit_admin_resource_image_path(@resource_image), notice: 'La photo a bien été modifiée'
      else
        render :edit
      end
    end

    def edit_photo
      @resource_image = ResourceImage.find(params[:id])
      @image = @resource_image.image_url
      @redirect_url = photo_upload_success_admin_resource_image_url
      @form = ResourceImageUploader
      render :edit_image
    end

    def photo_upload_success
      resource_image = ResourceImageUploader.handle_success(params)
      redirect_to edit_admin_resource_image_path(resource_image)
    end

    def destroy
      @resource_image = ResourceImage.find(params[:id])

      if @resource_image.destroy
        redirect_to admin_resource_images_path, flash: {
          success: "La photo \"#{@resource_image.title}\" a bien été supprimée"
        }
      else
        redirect_to edit_admin_resource_image_path(@resource_image), flash: {
          notice: "La photo \"#{@resource_image.title}\" n'a pas pu être supprimée"
        }
      end
    end

    private

    def resource_image_params
      params.require(:resource_image).permit(:title, :image_url)
    end
  end
end
