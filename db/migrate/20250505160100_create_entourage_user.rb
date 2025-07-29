class CreateEntourageUser < ActiveRecord::Migration[6.1]
  def up
    return if EnvironmentHelper.test?
    return if User.find_entourage_user.present?

    raise ArgumentError unless phone = ENV['ENTOURAGE_USER_PHONE']

    UserServices::PublicUserBuilder.new(params: {
      phone: phone, email: 'contact@entourage.social', first_name: 'Entourage'
    }, community: Community.new(:entourage)).create
  end

  def down
    User.find_by(phone: ENV['ENTOURAGE_USER_PHONE'], email: 'contact@entourage.social').destroy
  end
end
