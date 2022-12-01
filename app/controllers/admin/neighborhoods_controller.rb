module Admin
  class NeighborhoodsController < Admin::BaseController
    layout 'admin_large'

    before_action :set_neighborhood, only: [:edit, :update, :edit_image, :update_image, :show_members, :show_outings, :show_outing_chat_messages, :show_posts, :show_post_comments, :edit_owner, :update_owner]

    def index
      @params = params.permit([:area, :search]).to_h
      @area = params[:area].presence&.to_sym || :all

      @neighborhoods = Neighborhood.unscoped.includes([:user, :taggings])
      @neighborhoods = @neighborhoods.search_by(params[:search]) if params[:search].present?
      @neighborhoods = @neighborhoods.with_moderation_area(@area.to_s) if @area && @area != :all
      @neighborhoods = @neighborhoods.order(created_at: :desc).page(page).per(per)
    end

    def edit
    end

    def update
      @neighborhood.assign_attributes(neighborhood_params)

      if @neighborhood.save
        redirect_to edit_admin_neighborhood_path(@neighborhood)
      else
        render :edit
      end
    end

    def edit_image
      @neighborhood_images = NeighborhoodImage.all
    end

    def update_image
      @neighborhood.assign_attributes(neighborhood_params)

      if @neighborhood.save
        redirect_to edit_admin_neighborhood_path(@neighborhood)
      else
        @neighborhood_images = NeighborhoodImage.all
        render :edit_image
      end
    end

    def show_members
    end

    def show_outings
      @outings = @neighborhood.outings.page(page).per(per)
    end

    def show_outing_chat_messages
      @outing = Outing.find(params[:outing_id])
      @chat_messages = @outing.chat_messages.page(page).per(per)
    end

    def show_posts
      @posts = @neighborhood.posts.page(page).per(per).includes([:user])
    end

    def show_post_comments
      @post = ChatMessage.find(params[:post_id])

      if @post.messageable == @neighborhood
        @comments = @post.children.page(page).per(per).includes([:user])
      else
        redirect_to edit_admin_neighborhood_path(@neighborhood), alert: "La page n'est pas disponible"
      end
    end

    def edit_owner
    end

    def update_owner
      user_id = neighborhood_params[:user_id]
      message = neighborhood_params[:change_ownership_message]

      EntourageServices::ChangeOwner.new(@neighborhood).to(user_id, message) do |success, error_message|
        if success
          redirect_to [:edit, :admin, @neighborhood], notice: "Mise à jour réussie"
        else
          redirect_to [:edit_owner, :admin, @neighborhood], alert: error_message
        end
      end
    end

    private

    def set_neighborhood
      @neighborhood = Neighborhood.unscoped.find(params[:id])
    end

    def neighborhood_params
      params.require(:neighborhood).permit(:status, :name, :description, :interest_list, :neighborhood_image_id, :google_place_id, :user_id, :change_ownership_message, interests: [])
    end

    def page
      params[:page] || 1
    end

    def per
      params[:per] || 25
    end
  end
end
