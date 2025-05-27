module Admin
  class OutingsController < Admin::BaseController
    layout 'admin_large'

    EXPORT_PERIOD = 1.month

    def index
      @outings = filtered_outings.page(page).per(per)
    end

    def download_list_export
      outing_ids = filtered_outings.where(%((
        (group_type = 'outing' and metadata->>'starts_at' >= :starts_after) or
        (group_type = 'action' and created_at >= :created_after)
      )), {
        starts_after: EXPORT_PERIOD.ago,
        created_after: EXPORT_PERIOD.ago,
      }).pluck(:id).compact.uniq

      MemberMailer.entourages_csv_export(outing_ids, current_user.email).deliver_later

      redirect_to admin_outings_url(params: filter_params), flash: { success: "Vous recevrez l'export par mail (actions créées depuis moins d'un mois ou événements ayant eu lieu il y a moins d'un mois)" }
    end

    private

    def page
      params[:page] || 1
    end

    def per
      params[:per] || 25
    end

    def filter_params
      params.permit(:search, :area, :moderator_id, status: []).to_h
    end

    def filtered_outings
      @params = filter_params
      @area = params[:area].presence&.to_sym || :all

      @outings = Outing.unscope(:order)
        .like(params[:search])
        .with_moderation
        .with_moderation_area(@area.to_s)
        .with_moderator_reads_for(user: current_user)
        .with_entourage_type(params[:entourage_type])
        .with_status(params[:status])
        .moderator_search(params[:moderator_id])
        .select(%(
          entourages.*,
          entourage_moderations.moderated_at is not null or entourages.created_at < '2018-01-01' as moderated
        ))
        .order(Arel.sql("metadata->>'starts_at' DESC"))
        .order(Arel.sql("case when status = 'open' then 1 else 2 end"))
        .order(Arel.sql("entourages.created_at DESC"))
    end
  end
end
