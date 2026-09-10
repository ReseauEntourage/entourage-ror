module Admin
  class OpenAgendaSourcesController < Admin::BaseController
    layout 'admin_large'

    before_action :set_source, only: [:show, :edit, :update, :destroy, :sync]

    STATUS_FILTERS = OpenAgendaSource::STATUSES

    def index
      @status_filter = params[:status].presence_in(STATUS_FILTERS)
      @mapped_filter = params[:mapped].presence_in(%w[yes no])

      @open_agenda_sources = OpenAgendaSource.includes(:partner).ordered
      @open_agenda_sources = @open_agenda_sources.where(status: @status_filter) if @status_filter
      @open_agenda_sources = @open_agenda_sources.mapped if @mapped_filter == 'yes'
      @open_agenda_sources = @open_agenda_sources.unmapped if @mapped_filter == 'no'

      @total_count = OpenAgendaSource.count
      @counts = OpenAgendaSource.group(:status).count
    end

    def new
      @open_agenda_source = OpenAgendaSource.new(city: params[:city], partner_id: params[:partner_id])
    end

    def create
      @open_agenda_source = OpenAgendaSource.new(source_params)

      if @open_agenda_source.save
        @open_agenda_source.sync!
        redirect_to [:admin, @open_agenda_source], notice: "Source créée (statut : #{@open_agenda_source.reload.status})"
      else
        render :new
      end
    end

    def show
      @upcoming_events = @open_agenda_source.upcoming_events
    end

    def edit
    end

    def update
      @open_agenda_source.assign_attributes(source_params)

      if @open_agenda_source.save
        redirect_to [:admin, @open_agenda_source], notice: 'Source mise à jour'
      else
        render :edit
      end
    end

    def destroy
      @open_agenda_source.destroy
      redirect_to admin_open_agenda_sources_path, notice: 'Source supprimée'
    end

    def sync
      @open_agenda_source.sync!
      @open_agenda_source.reload

      if @open_agenda_source.status == 'exploitable'
        redirect_to [:admin, @open_agenda_source], notice: "Synchronisation réussie — #{@open_agenda_source.upcoming_events_count} événement(s) à venir"
      else
        redirect_to [:admin, @open_agenda_source], alert: "Agenda non exploitable : #{@open_agenda_source.last_error}"
      end
    end

    private

    def set_source
      @open_agenda_source = OpenAgendaSource.find(params[:id])
    end

    def source_params
      params.require(:open_agenda_source).permit(:name, :agenda_uid, :partner_id, :poi_id, :city, :notes)
    end
  end
end
