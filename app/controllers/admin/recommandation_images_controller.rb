module Admin
  class RecommandationImagesController < Admin::BaseController
    def index
      @recommandation_images = RecommandationImage.order(title: :asc)
    end

    def new
      @recommandation_image = RecommandationImage.new
    end

    def create
      @recommandation_image = RecommandationImage.new(recommandation_image_params)
      if @recommandation_image.save
        redirect_to edit_admin_recommandation_image_path(@recommandation_image.id)
      else
        render :new
      end
    end

    def edit
      @recommandation_image = RecommandationImage.find(params[:id])
    end

    def update
      @recommandation_image = RecommandationImage.find(params[:id])
      @recommandation_image.assign_attributes(recommandation_image_params)

      if @recommandation_image.save
        redirect_to edit_admin_recommandation_image_path(@recommandation_image), notice: "La photo a bien été modifiée"
      else
        render :edit
      end
    end

    def edit_photo
      @recommandation_image = RecommandationImage.find(params[:id])
      @image = @recommandation_image.image_url
      @redirect_url = photo_upload_success_admin_recommandation_image_url
      @form = RecommandationImageUploader
      render :edit_image
    end

    def photo_upload_success
      recommandation_image = RecommandationImageUploader.handle_success(params)
      redirect_to edit_admin_recommandation_image_path(recommandation_image)
    end

    def destroy
      @recommandation_image = RecommandationImage.find(params[:id])

      if @recommandation_image.destroy
        redirect_to admin_recommandation_images_path, flash: {
          success: "La photo \"#{@recommandation_image.title}\" a bien été supprimée"
        }
      else
        redirect_to edit_admin_recommandation_image_path(@recommandation_image), flash: {
          notice: "La photo \"#{@recommandation_image.title}\" n'a pas pu être supprimée"
        }
      end
    end

    private

    def recommandation_image_params
      params.require(:recommandation_image).permit(:title, :image_url)
    end
  end
end
