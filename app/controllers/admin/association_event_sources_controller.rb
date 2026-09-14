module Admin
  class AssociationEventSourcesController < Admin::BaseController
    layout 'admin_large'

    before_action :set_source, only: [:show, :edit, :update, :destroy, :sync]

    STATUS_FILTERS = AssociationEventSource::STATUSES
    PROVIDER_FILTERS = AssociationEventSource::PROVIDERS

    def index
      @status_filter = params[:status].presence_in(STATUS_FILTERS)
      @provider_filter = params[:provider].presence_in(PROVIDER_FILTERS)
      @mapped_filter = params[:mapped].presence_in(%w[yes no])

      @association_event_sources = AssociationEventSource.includes(:partner).ordered
      @association_event_sources = @association_event_sources.where(status: @status_filter) if @status_filter
      @association_event_sources = @association_event_sources.where(provider: @provider_filter) if @provider_filter
      @association_event_sources = @association_event_sources.mapped if @mapped_filter == 'yes'
      @association_event_sources = @association_event_sources.unmapped if @mapped_filter == 'no'

      @total_count = AssociationEventSource.count
      @counts = AssociationEventSource.group(:status).count
      @provider_counts = AssociationEventSource.group(:provider).count
    end

    def new
      @association_event_source = AssociationEventSource.new(provider: params[:provider].presence_in(PROVIDER_FILTERS) || 'open_agenda', city: params[:city], partner_id: params[:partner_id])
    end

    def create
      @association_event_source = AssociationEventSource.new(source_params)

      if @association_event_source.save
        @association_event_source.sync!
        redirect_to [:admin, @association_event_source], notice: "Source créée (statut : #{@association_event_source.reload.status})"
      else
        render :new
      end
    end

    def show
      @upcoming_events = @association_event_source.upcoming_events
    end

    def edit
    end

    def update
      @association_event_source.assign_attributes(source_params)

      if @association_event_source.save
        redirect_to [:admin, @association_event_source], notice: 'Source mise à jour'
      else
        render :edit
      end
    end

    def destroy
      @association_event_source.destroy
      redirect_to admin_association_event_sources_path, notice: 'Source supprimée'
    end

    def sync
      @association_event_source.sync!
      @association_event_source.reload

      if @association_event_source.status == 'exploitable'
        redirect_to [:admin, @association_event_source], notice: "Synchronisation réussie — #{@association_event_source.upcoming_events_count} événement(s) à venir"
      else
        redirect_to [:admin, @association_event_source], alert: "Source non exploitable : #{@association_event_source.last_error}"
      end
    end

    private

    def set_source
      @association_event_source = AssociationEventSource.find(params[:id])
    end

    def source_params
      params.require(:association_event_source).permit(
        :provider, :name, :agenda_uid, :helloasso_organization_slug, :partner_id, :poi_id, :city, :notes
      )
    end
  end
end
