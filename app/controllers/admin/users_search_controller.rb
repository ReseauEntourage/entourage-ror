module Admin
  class UsersSearchController < Admin::BaseController
    def public_user_autocomplete
      users = User.where(community: current_user.community.slug)
                  .search_by(params[:search])
                  .order('last_name ASC')
                  .limit(25)
      results = users.map {|u| {label: u.full_name, value: u.full_name, id: u.id} }
      render json: results
    end
  end
end
