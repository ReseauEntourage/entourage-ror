module Admin
  class EntourageImagesController < Admin::BaseController
    def index
      @entourage_images = EntourageImage.includes(:landscape_url_medium, :portrait_url_medium).order(title: :asc)
    end

    def new
      @entourage_image = EntourageImage.new
    end

    def create
      @entourage_image = EntourageImage.new(entourage_image_params)
      if @entourage_image.save
        redirect_to edit_admin_entourage_image_path(@entourage_image.id)
      else
        render :new
      end
    end

    def edit
      @entourage_image = EntourageImage.find(params[:id])
    end

    def update
      @entourage_image = EntourageImage.find(params[:id])
      @entourage_image.assign_attributes(entourage_image_params)

      if @entourage_image.save
        redirect_to edit_admin_entourage_image_path(@entourage_image), notice: 'La photo a bien été modifiée'
      else
        render :edit
      end
    end

    def edit_landscape
      @entourage_image = EntourageImage.find(params[:id])
      @image = @entourage_image.landscape_url
      @redirect_url = landscape_upload_success_admin_entourage_image_url
      @form = EntourageImageLandscapeUploader
      render :edit_image
    end

    def edit_portrait
      @entourage_image = EntourageImage.find(params[:id])
      @image = @entourage_image.portrait_url
      @redirect_url = portrait_upload_success_admin_entourage_image_url
      @form = EntourageImagePortraitUploader
      render :edit_image
    end

    def landscape_upload_success
      entourage_image = EntourageImageLandscapeUploader.handle_success(params)
      redirect_to edit_admin_entourage_image_path(entourage_image)
    end

    def portrait_upload_success
      entourage_image = EntourageImagePortraitUploader.handle_success(params)
      redirect_to edit_admin_entourage_image_path(entourage_image)
    end

    def destroy
      @entourage_image = EntourageImage.find(params[:id])

      if @entourage_image.destroy
        redirect_to admin_entourage_images_path, flash: {
          success: "La photo \"#{@entourage_image.title}\" a bien été supprimée"
        }
      else
        redirect_to edit_admin_entourage_image_path(@entourage_image), flash: {
          notice: "La photo d'événement \"#{@entourage_image.title}\" n'a pas pu être supprimée"
        }
      end
    end

    private

    def entourage_image_params
      params.require(:entourage_image).permit(:title, :landscape_url, :portrait_url)
    end
  end
end
