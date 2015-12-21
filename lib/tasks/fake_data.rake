namespace :fake_data do

  desc "create fake registration request"
  task registration_request: :environment do
    RegistrationRequest.destroy_all
    organization = {name: "foo",
                    local_entity: "bar",
                    address: "2 rue de l'église",
                    phone: "+33612345678",
                    email: "some@email.com",
                    website_url: "http://foobar.com",
                    description: "lorem ipsum",
                    logo_key: "some_key.jpg"}
    RegistrationRequest.create!(status: "pending", extra: {organization: organization,
                                                           user: {first_name: "John",
                                                                  last_name: "Doe",
                                                                  phone: "+33612345678",
                                                                  email: "some@email.com"}})
    RegistrationRequest.create!(status: "pending", extra: {organization: organization,
                                                           user: {first_name: "John",
                                                                  last_name: "Doe2",
                                                                  phone: "+33612345679",
                                                                  email: "some1@email.com"}})
  end
end
