class CreateEntourageUser < ActiveRecord::Migration[6.1]
  def up
    raise ArgumentError unless phone = ENV["ENTOURAGE_USER_PHONE"]

    UserServices::PublicUserBuilder.new(params: {
      phone: phone, email: "contact@entourage.social", first_name: "Entourage"
    }, community: Community.new(:entourage)).create
  end

  def down
    User.find_by(email: "contact@entourage.social", first_name: "Entourage").destroy
  end
end
