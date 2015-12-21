ActiveAdmin.register_page "Registration requests" do
  controller do
    define_method(:index) do
      redirect_to registration_requests_path(status: "pending")
    end
  end
end