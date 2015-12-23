class UserPresenter
  delegate :snap_to_road,
           :simplified_tour,
           :tour_types,
           :date_range, to: :user_default

  def initialize(user:)
    @user = user
  end

  def user_default
    PreferenceServices::UserDefault.new(user: user)
  end

  private
  attr_reader :user
end