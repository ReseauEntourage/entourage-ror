module Admin
  class NeighborhoodImagesController < Admin::BaseController
    def index
      @neighborhood_images = NeighborhoodImage.includes(:image_url_medium).order(title: :asc)
    end

    def new
      @neighborhood_image = NeighborhoodImage.new
    end

    def create
      @neighborhood_image = NeighborhoodImage.new(neighborhood_image_params)
      if @neighborhood_image.save
        redirect_to edit_admin_neighborhood_image_path(@neighborhood_image.id)
      else
        render :new
      end
    end

    def edit
      @neighborhood_image = NeighborhoodImage.find(params[:id])
    end

    def update
      @neighborhood_image = NeighborhoodImage.find(params[:id])
      @neighborhood_image.assign_attributes(neighborhood_image_params)

      if @neighborhood_image.save
        redirect_to edit_admin_neighborhood_image_path(@neighborhood_image), notice: 'La photo a bien été modifiée'
      else
        render :edit
      end
    end

    def edit_photo
      @neighborhood_image = NeighborhoodImage.find(params[:id])
      @image = @neighborhood_image.image_url
      @redirect_url = photo_upload_success_admin_neighborhood_image_url
      @form = NeighborhoodImageUploader
      render :edit_image
    end

    def photo_upload_success
      neighborhood_image = NeighborhoodImageUploader.handle_success(params)
      redirect_to edit_admin_neighborhood_image_path(neighborhood_image)
    end

    def destroy
      @neighborhood_image = NeighborhoodImage.find(params[:id])

      if @neighborhood_image.destroy
        redirect_to admin_neighborhood_images_path, flash: {
          success: "La photo \"#{@neighborhood_image.title}\" a bien été supprimée"
        }
      else
        redirect_to edit_admin_neighborhood_image_path(@neighborhood_image), flash: {
          notice: "La photo d'événement \"#{@neighborhood_image.title}\" n'a pas pu être supprimée"
        }
      end
    end

    private

    def neighborhood_image_params
      params.require(:neighborhood_image).permit(:title, :image_url)
    end
  end
end
