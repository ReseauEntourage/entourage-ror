namespace :fake_data do

  desc "create test users account"
  task test_accounts: :environment do
    tecknoworks = Organization.create(name: "tecknoworks", phone: "+401234567", description: "tecknoworks", address: "foobar")
    User.create(user_type: "pro", phone: "+40742224359", sms_code: "123456", organization: tecknoworks, email: "brindusa.duma@tecknoworks.com")
    User.create(user_type: "pro", phone: "+33740884267", sms_code: "123456", organization: tecknoworks, email: "chip+1@tecknoworks.com")
    User.create(user_type: "pro", phone: "+40743044174", sms_code: "123456", organization: tecknoworks, email: "mihai.ionescu@tecknoworks.com")
    User.create(user_type: "pro", phone: "+33623456789", sms_code: "123456", organization: tecknoworks, email: "entourage@tecknoworks.com")
    User.create(user_type: "pro", phone: "+40724591112", sms_code: "123456", organization: tecknoworks, email: "vasile.corde54@tecknoworks.com")
    User.create(user_type: "pro", phone: "+40724591113", sms_code: "123456", organization: tecknoworks, email: "vasile.corde6@tecknoworks.com")
    User.create(user_type: "pro", phone: "+40724591114", sms_code: "123456", organization: tecknoworks, email: "vasile.corde7@tecknoworks.com")
    User.create(user_type: "pro", phone: "+40723199641", sms_code: "123456", organization: tecknoworks, email: "vasile.cordea@tecknoworks.com")
  end
end
