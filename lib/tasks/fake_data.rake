namespace :fake_data do

  desc "create test users account"
  task test_accounts: :environment do
    tecknoworks = Organization.where(name: "tecknoworks", phone: "+401234567", description: "tecknoworks", address: "foobar").first_or_create!
    User.where(phone: ["+40742224359", "+33740884267", "+40743044174", "+33623456789", "+40724591112", "+40724591113", "+40724591114", "+40723199641"]).destroy_all
    User.create!(phone: "+40742224359", user_type: "pro", sms_code: "123456", organization: tecknoworks, email: "brindusa.duma@tecknoworks.com", token: SecureRandom.hex(8), first_name: "foo", last_name: "bar")
    User.create!(phone: "+33740884267", user_type: "pro", sms_code: "123456", organization: tecknoworks, email: "chip+1@tecknoworks.com", token: SecureRandom.hex(8), first_name: "foo", last_name: "bar")
    User.create!(phone: "+40743044174", user_type: "pro", sms_code: "123456", organization: tecknoworks, email: "mihai.ionescu@tecknoworks.com", token: SecureRandom.hex(8), first_name: "foo", last_name: "bar")
    User.create!(phone: "+33623456789", user_type: "pro", sms_code: "123456", organization: tecknoworks, email: "entourage@tecknoworks.com", token: SecureRandom.hex(8), first_name: "foo", last_name: "bar")
    User.create!(phone: "+40724591112", user_type: "pro", sms_code: "123456", organization: tecknoworks, email: "vasile.corde54@tecknoworks.com", token: SecureRandom.hex(8), first_name: "foo", last_name: "bar")
    User.create!(phone: "+40724591113", user_type: "pro", sms_code: "123456", organization: tecknoworks, email: "vasile.corde6@tecknoworks.com", token: SecureRandom.hex(8), first_name: "foo", last_name: "bar")
    User.create!(phone: "+40724591114", user_type: "pro", sms_code: "123456", organization: tecknoworks, email: "vasile.corde7@tecknoworks.com", token: SecureRandom.hex(8), first_name: "foo", last_name: "bar")
    User.create!(phone: "+40723199641", user_type: "pro", sms_code: "123456", organization: tecknoworks, email: "vasile.cordea@tecknoworks.com", token: SecureRandom.hex(8), first_name: "foo", last_name: "bar")
  end
end
