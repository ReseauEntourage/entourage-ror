FactoryGirl.define do
  factory :registration_request do
    status"pending"
    extra { {organization: {name: "namefoo", local_entity: "bar", address: "2 rue de l'église", phone: "+3361234567", email: "some@email.com", webiste_url: "http://foobar.com", description: "lorem ipsum", logo_key: "some_key.jpg"}, user:{ first_name:"John", last_name:"Doe", phone:"+3361234567", email:"some@email.com"}} }
  end
end
