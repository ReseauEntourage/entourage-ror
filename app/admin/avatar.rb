ActiveAdmin.register_page "Avatars" do
  controller do
    define_method(:index) do
      redirect_to moderate_admin_users_path(validation_status: "validated")
    end
  end
end