module Admin
  class UserRelationshipsController < Admin::BaseController
    def destroy
      UserRelationship.where(source_user: params[:source_user],
                              target_user: params[:target_user]).first!.destroy
      redirect_to edit_admin_ambassador_path(params[:source_user])
    end
  end
end