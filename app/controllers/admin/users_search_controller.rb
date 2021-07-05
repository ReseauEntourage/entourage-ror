module Admin
  class UsersSearchController < Admin::BaseController
    def public_user_autocomplete
      users = User.where(community: current_user.community.slug)
                  .search_by(search_like, search_like, search_like, search_strip, search_like)
                  .order("last_name ASC")
                  .limit(25)
      results = users.map {|u| {label: u.full_name, value: u.full_name, id: u.id} }
      render json: results
    end

    def user_search
      @params = params.permit([:status]).to_h
      @users = User.includes(:organization)
                   .where(community: current_user.community.slug)
                   .search_by(search_like, search_like, search_like, search_strip, search_like)
                   .order("last_sign_in_at desc nulls last")
                   .page(params[:page])
                   .per(25)
      render "admin/users/index"
    end

    private

    def search_like
      "%#{search_strip}%"
    end

    def search_strip
      params[:search] && params[:search].strip
    end
  end
end
