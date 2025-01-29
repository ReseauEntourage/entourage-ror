module Admin
  class NeighborhoodsController < Admin::BaseController
    layout 'admin_large'

    before_action :set_neighborhood, only: [:edit, :update, :destroy, :reactivate, :edit_image, :update_image, :show_members, :show_outings, :show_outing_posts, :show_outing_post_comments, :show_posts, :show_post_comments, :edit_owner, :update_owner, :read_all_messages, :join, :unjoin, :message, :outing_message, :destroy_outing_message]

    before_action :set_neighborhood_forced_join_request, only: [:message]
    before_action :set_outing_forced_join_request, only: [:outing_message]

    before_action :set_chat_message, only: [:unread_message, :destroy_message, :destroy_outing_message]
    before_action :set_join_request, only: [:join, :unjoin]

    def index
      @params = params.permit([:area, :search]).to_h
      @area = params[:area].presence&.to_sym || :all

      @neighborhoods = Neighborhood.unscoped.includes([:user, :interests])
      @neighborhoods = @neighborhoods.search_by(params[:search]) if params[:search].present?
      @neighborhoods = @neighborhoods.with_moderation_area(@area.to_s) if @area && @area != :all
      @neighborhoods = @neighborhoods
        .with_moderator_reads_for(user: current_user)
        .join_chat_message_with_images
        .join_chat_messages_on_max_created_at
        .select(%(
          neighborhoods.*,
          moderator_reads is null as unread,
          moderator_reads is null and neighborhoods_imageable.id is not null as unread_images
        ))
        .order(Arel.sql("case when status = 'active' then 1 else 2 end"))
        .order(Arel.sql(%(
          case
          when moderator_reads is null then 0
          when moderator_reads is null and neighborhoods_imageable.id is not null then 1
          when neighborhoods_messageable.max_created_at >= moderator_reads.read_at then 2
          else 3
          end
        )))
        .order(Arel.sql(%(
          neighborhoods.number_of_people DESC
        ))).page(page).per(per)

      @message_count = ChatMessage
        .with_moderator_reads_for(user: current_user)
        .where(messageable: @neighborhoods.map(&:id))
        .group(:messageable_id)
        .select(%{
          messageable_id,
          sum(case when chat_messages.content <> '' then 1 else 0 end) as total,
          sum(case when chat_messages.created_at >= moderator_reads.read_at then 1 else 0 end) as unread,
          sum(case when chat_messages.created_at >= moderator_reads.read_at and chat_messages.image_url is not null then 1 else 0 end) as unread_images
        })

      @message_count = Hash[@message_count.map { |m| [m.messageable_id, m] }]
      @message_count.default = OpenStruct.new(unread: 0, total: 0)
    end

    def unread_posts
      @params = params.permit([:area, :search]).to_h
      @area = params[:area].presence&.to_sym || :all

      @posts = ChatMessage
        .visible
        .where(messageable_type: :Neighborhood)
        .where(comments_count: 0)
        .where("chat_messages.created_at > ?", 3.months.ago)
        .where(ancestry: nil)
        .joins("left join neighborhoods on neighborhoods.id = chat_messages.messageable_id and chat_messages.messageable_type = 'Neighborhood'")
        .where(messageable_id: Neighborhood
          .search_by(params[:search])
          .with_moderation_area(@area.to_s)
        )
        .includes(:messageable, :user)
        .order(created_at: :desc)
        .page(page)
        .per(per)
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

    def destroy
      if @neighborhood.update_attribute(:status, :deleted)
        redirect_to admin_neighborhoods_path, notice: "Le groupe de voisins #{@neighborhood.name} a bien été supprimé"
      else
        redirect_to edit_admin_neighborhood_path(@neighborhood), error: "Le groupe de voisins #{@neighborhood.name} n'a pas pu être supprimé"
      end
    end

    def reactivate
      if @neighborhood.update_attribute(:status, :active)
        redirect_to admin_neighborhoods_path, notice: "Le groupe de voisins #{@neighborhood.name} a bien été réactivé"
      else
        redirect_to edit_admin_neighborhood_path(@neighborhood), error: "Le groupe de voisins #{@neighborhood.name} n'a pas pu être réactivé"
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
      @members = @neighborhood.members.page(page).per(per)
    end

    def show_outings
      @outings = @neighborhood.outings.includes([:interests]).page(page).per(per)
    end

    def show_outing_posts
      @outing = Outing.find(params[:outing_id])
      @posts = @outing.parent_chat_messages.order(created_at: :desc).page(page).per(per).includes(:user, :translation)
    end

    def show_outing_post_comments
      @post = ChatMessage.find(params[:post_id])

      messageable = @post.messageable

      if messageable.is_a?(Entourage) && messageable.outing?
        @outing = messageable
        @comments = @post.children.ordered.page(page).per(per).includes(:user, :translation)
      else
        redirect_to edit_admin_neighborhood_path(@neighborhood), alert: "La page n'est pas disponible"
      end
    end

    def show_posts
      @posts = @neighborhood.posts.order(created_at: :desc).page(page).per(per).includes(:user, :survey, :translation)
      @moderator_read = @neighborhood.moderator_read_for(user: current_user)
    end

    def show_post_comments
      @post = ChatMessage.find(params[:post_id])

      if @post.messageable == @neighborhood
        @comments = @post.children.order(created_at: :desc).page(page).per(per).includes(:user, :translation)
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
          redirect_to [:edit, :admin, @neighborhood], notice: 'Mise à jour réussie'
        else
          redirect_to [:edit_owner, :admin, @neighborhood], alert: error_message
        end
      end
    end

    def join
      return redirect_to show_members_admin_neighborhood_path(@neighborhood) if @join_request.present? && @join_request.accepted?

      if @join_request.present?
        @join_request.status = :accepted
      else
        @join_request = JoinRequest.new(joinable: @neighborhood, user: current_user, role: :member, status: :accepted)
      end

      if @join_request.save
        redirect_to show_members_admin_neighborhood_path(@neighborhood), notice: 'Vous avez bien rejoint le groupe'
      else
        redirect_to show_members_admin_neighborhood_path(@neighborhood), error: "Vous n'avez pas pu rejoindre le groupe : #{@join_request.errors.full_messages}"
      end
    end

    def unjoin
      return redirect_to show_members_admin_neighborhood_path(@neighborhood) if @join_request.present? && @join_request.cancelled?

      if @join_request.present?
        @join_request.status = :cancelled
      else
        @join_request = JoinRequest.new(joinable: @neighborhood, user: current_user, role: :member, status: :cancelled)
      end

      if @join_request.save
        redirect_to show_members_admin_neighborhood_path(@neighborhood), notice: 'Vous avez bien quitté le groupe'
      else
        redirect_to show_members_admin_neighborhood_path(@neighborhood), error: "Vous n'avez pas pu quitter le groupe : #{@join_request.errors.full_messages}"
      end
    end

    # chat_message
    def read_all_messages
      ModeratorReadsService
        .new(instance: @neighborhood, moderator: current_user)
        .mark_as_read(at: Time.zone.now)

      redirect_to show_posts_admin_neighborhood_path(@neighborhood)
    end

    def unread_all_messages
      ModeratorReadsService
        .new(instance: @neighborhood, moderator: current_user)
        .mark_as_unread

      redirect_to show_posts_admin_neighborhood_path(@neighborhood)
    end

    def unread_message
      ModeratorReadsService
        .new(instance: @chat_message.messageable, moderator: current_user)
        .mark_as_read(at: @chat_message.created_at)

      redirect_to show_posts_admin_neighborhood_path(@chat_message.messageable)
    end

    # POST
    def message
      ChatServices::ChatMessageBuilder.new(
        params: chat_messages_params,
        user: current_user,
        joinable: @neighborhood,
        join_request: @join_request
      ).create do |on|
        redirection = if chat_messages_params.has_key?(:parent_id)
          show_post_comments_admin_neighborhood_path(@neighborhood, post_id: chat_messages_params[:parent_id])
        else
          show_posts_admin_neighborhood_path(@neighborhood)
        end

        on.success do |message|
          @message = message

          @join_request.set_chat_messages_as_read_from(message.created_at)

          respond_to do |format|
            format.js
            format.html { redirect_to redirection }
          end
        end

        on.failure do |message|
          redirect_to redirection, alert: "Erreur lors de l'envoi du message : #{message.errors.full_messages.to_sentence}"
        end
      end
    end

    # POST
    def outing_message
      @outing = Outing.find(params[:outing_id])

      ChatServices::ChatMessageBuilder.new(
        params: chat_messages_params,
        user: current_user,
        joinable: @outing,
        join_request: @join_request
      ).create do |on|
        redirection = if chat_messages_params.has_key?(:parent_id)
          show_outing_post_comments_admin_neighborhood_path(@neighborhood, post_id: chat_messages_params[:parent_id])
        else
          show_outing_posts_admin_neighborhood_path(@neighborhood, outing_id: @outing.id)
        end

        on.success do |message|
          @join_request.set_chat_messages_as_read_from(message.created_at)

          redirect_to redirection
        end

        on.failure do |message|
          redirect_to redirection, alert: "Erreur lors de l'envoi du message : #{message.errors.full_messages.to_sentence}"
        end
      end
    end

    # DELETE
    def destroy_message
      ChatServices::Deleter.new(user: current_user, chat_message: @chat_message).delete(true) do |on|
        redirection = if @chat_message.has_parent?
          show_post_comments_admin_neighborhood_path(@chat_message.messageable, post_id: @chat_message.parent_id)
        else
          show_posts_admin_neighborhood_path(@chat_message.messageable)
        end

        on.success do |chat_message|
          respond_to do |format|
            format.js
            format.html { redirect_to redirection }
          end
        end

        on.failure do |chat_message|
          format.html { redirect_to redirection, alert: chat_message.errors.full_messages }
        end

        on.not_authorized do
          format.html { redirect_to redirection, alert: "You are not authorized to delete this chat_message" }
        end
      end
    end

    # DELETE
    def destroy_outing_message
      ChatServices::Deleter.new(user: current_user, chat_message: @chat_message).delete(true) do |on|
        redirection = if @chat_message.has_parent?
          show_outing_post_comments_admin_neighborhood_path(@neighborhood, post_id: @chat_message.parent_id)
        else
          show_outing_posts_admin_neighborhood_path(@neighborhood, outing_id: @chat_message.messageable_id)
        end

        on.success do |chat_message|
          redirect_to redirection
        end

        on.failure do |chat_message|
          redirect_to redirection, alert: chat_message.errors.full_messages
        end

        on.not_authorized do
          redirect_to redirection, alert: 'You are not authorized to delete this chat_message'
        end
      end
    end

    private

    def set_neighborhood
      @neighborhood = Neighborhood.unscoped.find(params[:id])
    end

    def set_neighborhood_forced_join_request
      @neighborhood = Neighborhood.unscoped.find(params[:id])

      @join_request = @neighborhood.set_forced_join_request_as_member!(current_user)
    end

    def set_outing_forced_join_request
      @outing = Outing.find(params[:outing_id])

      @join_request = @outing.set_forced_join_request_as_member!(current_user)
    end

    def set_chat_message
      @chat_message = ChatMessage.find(params[:chat_message_id])
    end

    def set_join_request
      @join_request = JoinRequest.where(joinable: @neighborhood, user: current_user).first
    end

    def neighborhood_params
      params.require(:neighborhood).permit(:status, :public, :name, :description, :interest_list, :neighborhood_image_id, :google_place_id, :user_id, :change_ownership_message, interests: [])
    end

    def chat_messages_params
      params.require(:chat_message).permit(:content, :parent_id)
    end

    def page
      params[:page] || 1
    end

    def per
      params[:per] || 25
    end
  end
end
