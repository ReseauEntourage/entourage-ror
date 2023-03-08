module Admin
  class NeighborhoodsController < Admin::BaseController
    layout 'admin_large'

    before_action :set_neighborhood, only: [:edit, :update, :destroy, :reactivate, :edit_image, :update_image, :show_members, :show_outings, :show_outing_posts, :show_outing_post_comments, :show_posts, :show_post_comments, :edit_owner, :update_owner, :read_all_messages, :message]
    before_action :set_forced_join_request, only: [:message]

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
        .order("case when status = 'active' then 1 else 2 end")
        .order(%(
          case
          when moderator_reads is null then 0
          when moderator_reads is null and neighborhoods_imageable.id is not null then 1
          when neighborhoods_messageable.max_created_at >= moderator_reads.read_at then 2
          else 3
          end
        ))
        .order(%(
          neighborhoods.created_at DESC
        )).page(page).per(per)

      @message_count = ConversationMessage
        .with_moderator_reads_for(user: current_user)
        .where(messageable: @neighborhoods.map(&:id))
        .group(:messageable_id)
        .select(%{
          messageable_id,
          sum(case when conversation_messages.content <> '' then 1 else 0 end) as total,
          sum(case when conversation_messages.created_at >= moderator_reads.read_at then 1 else 0 end) as unread,
          sum(case when conversation_messages.created_at >= moderator_reads.read_at and conversation_messages.image_url is not null then 1 else 0 end) as unread_images
        })

      @message_count = Hash[@message_count.map { |m| [m.messageable_id, m] }]
      @message_count.default = OpenStruct.new(unread: 0, total: 0)
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
    end

    def show_outings
      @outings = @neighborhood.outings.includes([:interests]).page(page).per(per)
    end

    def show_outing_posts
      @outing = Outing.find(params[:outing_id])
      @posts = @outing.parent_chat_messages.order(created_at: :desc).page(page).per(per)
    end

    def show_outing_post_comments
      @post = ChatMessage.find(params[:post_id])

      messageable = @post.messageable

      if messageable.is_a?(Entourage) && messageable.outing?
        @outing = messageable
        @comments = @post.children.ordered.page(page).per(per).includes([:user])
      else
        redirect_to edit_admin_neighborhood_path(@neighborhood), alert: "La page n'est pas disponible"
      end
    end

    def show_posts
      @posts = @neighborhood.posts.order(created_at: :desc).page(page).per(per).includes([:user])
      @moderator_read = @neighborhood.moderator_read_for(user: current_user)
    end

    def show_post_comments
      @post = ChatMessage.find(params[:post_id])

      if @post.messageable == @neighborhood
        @comments = @post.children.order(created_at: :desc).page(page).per(per).includes([:user])
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
      chat_message = ChatMessage.find(params[:chat_message_id])

      ModeratorReadsService
        .new(instance: chat_message.messageable, moderator: current_user)
        .mark_as_read(at: chat_message.created_at)

      redirect_to show_posts_admin_neighborhood_path(chat_message.messageable)
    end

    def message
      ChatServices::ChatMessageBuilder.new(
        params: chat_messages_params,
        user: current_user,
        joinable: @neighborhood,
        join_request: @join_request
      ).create do |on|
        on.success do |message|
          @join_request.update_column(:last_message_read, message.created_at)

          redirect_to show_posts_admin_neighborhood_path(@neighborhood)
        end

        on.failure do |message|
          redirect_to show_posts_admin_neighborhood_path(params[:id]), alert: "Erreur lors de l'envoi du message : #{message.errors.full_messages.to_sentence}"
        end
      end
    end

    def destroy_message
      chat_message = ChatMessage.find(params[:chat_message_id])

      return redirect_to show_posts_admin_neighborhood_path(chat_message.messageable), alert: "Impossible de supprimer une publication qui a des commentaires" if chat_message.children.any?

      chat_message.destroy

      redirect_to show_posts_admin_neighborhood_path(chat_message.messageable)
    end

    private

    def set_neighborhood
      @neighborhood = Neighborhood.unscoped.find(params[:id])
    end

    def set_forced_join_request
      @join_request = current_user.join_requests.find_by(joinable: @neighborhood)

      return if @join_request.present? && @join_request.accepted?

      if @join_request.present?
        @join_request.status = :accepted
      else
        @join_request = JoinRequest.new(joinable: @neighborhood, user: current_user, role: :member, status: :accepted)
      end

      @join_request.save!
    end

    def neighborhood_params
      params.require(:neighborhood).permit(:status, :name, :description, :interest_list, :neighborhood_image_id, :google_place_id, :user_id, :change_ownership_message, interests: [])
    end

    def chat_messages_params
      params.require(:chat_message).permit(:content)
    end

    def page
      params[:page] || 1
    end

    def per
      params[:per] || 25
    end
  end
end
