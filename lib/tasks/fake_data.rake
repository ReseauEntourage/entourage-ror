namespace :fake_data do

  desc "create test users account"
  task test_accounts: :environment do
    tecknoworks = Organization.create(name: "tecknoworks", phone: "+401234567", description: "tecknoworks", address: "foobar")
    User.create(user_type: "pro", phone: "+40742224359", sms_code: "123456", organization: tecknoworks, email: "brindusa.duma@tecknoworks.com")
  end
end
