module UserServices
  class FakeUser
    def create_user!
      User.create first_name: Faker::Name.first_name,
                  last_name: Faker::Name.last_name,
                  phone: "+336#{99999999-User.count}",
                  sms_code: rand(999999),
                  email: Faker::Internet.email,
                  organisation: Organisation.where(name: "Entourage").first,
                  token: SecureRandom.hex(16)
    end

    def user_with_maraude
      user = create_user!

    end
  end
end