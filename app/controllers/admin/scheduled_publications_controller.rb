module Admin
  class ScheduledPublicationsController < Admin::BaseController
    layout 'admin_large'

    before_action :set_scheduled_publication, except: [:index]

    TYPES = { post: 'ChatMessage', broadcast: 'ConversationMessageBroadcast' }.freeze

    def index
      @params = params.permit([:type, :search, :group_by]).to_h
      @type = params[:type].presence&.to_sym || :all
      @group_by = params[:group_by].presence&.to_sym || :month

      pending_scheduled_publications = ScheduledPublication.pending.order(:scheduled_at).includes(:publishable, :author, :neighborhood)
      @total_count = pending_scheduled_publications.count
      @total_post_count = pending_scheduled_publications.of_type(TYPES[:post]).count
      @total_broadcast_count = pending_scheduled_publications.of_type(TYPES[:broadcast]).count

      scheduled_publications = pending_scheduled_publications
      scheduled_publications = scheduled_publications.of_type(TYPES[@type]) if TYPES.key?(@type)
      scheduled_publications = scheduled_publications.select { |sp| sp.matches_search?(params[:search]) }

      @grouped_scheduled_publications = scheduled_publications.group_by do |scheduled_publication|
        @group_by == :week ? scheduled_publication.scheduled_at.in_time_zone('Paris').beginning_of_week : scheduled_publication.scheduled_at.in_time_zone('Paris').beginning_of_month
      end
    end

    def edit
      redirect_to edit_admin_neighborhood_message_broadcast_path(@scheduled_publication.publishable) if @scheduled_publication.broadcast?
    end

    def update
      return redirect_to return_path, alert: 'Cette publication ne peut pas être modifiée ici' unless @scheduled_publication.post?

      message = @scheduled_publication.publishable
      message.content = scheduled_publication_params[:content]

      scheduled_at = scheduled_at_param

      if scheduled_at.nil? || scheduled_at <= Time.zone.now
        flash.now[:alert] = "La date et l'heure de programmation sont obligatoires et doivent être dans le futur."
        return render :edit
      end

      if message.save && @scheduled_publication.update(scheduled_at: scheduled_at)
        PublishScheduledPublicationJob.cancel(@scheduled_publication.id)
        PublishScheduledPublicationJob.schedule(@scheduled_publication)

        redirect_to return_path, notice: 'La publication programmée a bien été mise à jour'
      else
        flash.now[:alert] = [message.errors.full_messages, @scheduled_publication.errors.full_messages].flatten.to_sentence
        render :edit
      end
    end

    def publish_now
      PublishScheduledPublicationJob.cancel(@scheduled_publication.id)
      ScheduledPublicationServices::Publisher.new(@scheduled_publication).publish!

      redirect_to return_path, notice: 'La publication a été effectuée immédiatement'
    end

    def cancel
      ScheduledPublicationServices::Canceller.new(@scheduled_publication).cancel!

      redirect_to return_path, notice: 'La publication programmée a été annulée'
    end

    private

    def set_scheduled_publication
      @scheduled_publication = ScheduledPublication.find(params[:id])
    end

    def scheduled_publication_params
      params.require(:scheduled_publication).permit(:content, :scheduled_date, :scheduled_time)
    end

    def scheduled_at_param
      return nil unless scheduled_publication_params[:scheduled_date].present? && scheduled_publication_params[:scheduled_time].present?

      Time.zone.parse("#{scheduled_publication_params[:scheduled_date]} #{scheduled_publication_params[:scheduled_time]}")
    rescue ArgumentError
      nil
    end

    def return_path
      return params[:return_to] if params[:return_to].present?
      return show_posts_admin_neighborhood_path(@scheduled_publication.neighborhood) if @scheduled_publication.post?

      admin_neighborhood_message_broadcasts_path
    end
  end
end
