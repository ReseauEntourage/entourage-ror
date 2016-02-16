ActiveAdmin.register_page "Utilisateurs" do
  controller do
    def index
      redirect_to admin_users_path
    end
  end
end
