class FeatureSwitch
  attr_reader :user

  def initialize user
    @user = user
  end

  def variant test
    self.send test, user
  end

  def feed user
    :v2
  end
end
