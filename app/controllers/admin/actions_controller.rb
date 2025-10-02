module Admin
  class ActionsController < Admin::BaseController
    layout 'admin_large'

    def index
      @params = params.permit(:search, :area, :moderator_id, :entourage_type, :moderated, status: []).to_h
      @area = params[:area].presence&.to_sym || :all

      @actions = Action.preload([:user])
        .like(params[:search])
        .with_user_id(params[:user_id] || params.dig(:q, :user_id_eq))
        .with_moderation
        .with_moderation_area(@area.to_s)
        .with_moderator_reads_for(user: current_user)
        .with_moderated(@params[:moderated])
        .with_entourage_type(params[:entourage_type])
        .with_status(params[:status])
        .moderator_search(params[:moderator_id])
        .select(%(
          entourages.*,
          entourage_moderations.moderated_at is not null or entourages.created_at < '2018-01-01' as moderated
        ))
        .order(Arel.sql("case when status = 'open' then 1 else 2 end"))
        .order(Arel.sql("entourages.created_at DESC"))
        .page(page)
        .per(per)
    end

    private

    def page
      params[:page] || 1
    end

    def per
      params[:per] || 25
    end
  end
end
