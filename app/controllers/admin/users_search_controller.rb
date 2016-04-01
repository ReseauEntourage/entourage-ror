module Admin
  class UsersSearchController < Admin::BaseController
    def public_user_search
      @users = User.type_public
                   .where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ? OR phone = ?",
                          search_param,
                          search_param,
                          search_param,
                          params[:search])
                   .order("last_name ASC")
                   .page(params[:page])
                   .per(25)
      render "admin/ambassadors/index"
    end

    def public_user_autocomplete
      users = User.type_public
                   .where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ? OR phone = ?",
                          search_param,
                          search_param,
                          search_param,
                          params[:term])
                   .order("last_name ASC")
                   .limit(25)
      results = users.map {|u| {label: u.full_name, value: u.full_name, id: u.id} }
      render json: results
    end

    def pro_user_search

    end

    private

    def search_param
      "%#{params[:search]}%"
    end
  end
end