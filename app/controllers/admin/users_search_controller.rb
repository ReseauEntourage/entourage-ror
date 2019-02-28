module Admin
  class UsersSearchController < Admin::BaseController
    def public_user_autocomplete
      users = User.where(community: current_user.community.slug)
                  .search_by(search_param, search_param, search_param, params[:search])
                  .order("last_name ASC")
                  .limit(25)
      results = users.map {|u| {label: u.full_name, value: u.full_name, id: u.id} }
      render json: results
    end

    def user_search
      @users = User.includes(:organization)
                   .where(community: current_user.community.slug)
                   .search_by(search_param, search_param, search_param, params[:search])
                   .order("last_name ASC")
                   .page(params[:page])
                   .per(25)
      render "admin/users/index"
    end

    private

    def search_param
      "%#{params[:search]}%"
    end
  end
end
