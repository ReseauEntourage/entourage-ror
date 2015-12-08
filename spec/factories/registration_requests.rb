FactoryGirl.define do
  factory :registration_request do
    status"pending"
    extra { {organization: {name: "namefoo", local_entity: "bar", address: "2 rue de l'église", phone: "+33612345678", email: "some@email.com", website_url: "http://foobar.com", description: "lorem ipsum", logo_key: "some_key.jpg"}, user:{ first_name:"John", last_name:"Doe", phone:"+33612345678", email:"some@email.com"}} }
  end
end
