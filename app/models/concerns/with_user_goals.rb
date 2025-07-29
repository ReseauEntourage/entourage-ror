module WithUserGoals
  extend ActiveSupport::Concern

  included do
    attribute :user_goals, :jsonb_set

    validates :user_goals, presence: true

    scope :for_user_goal, -> (user_goal) {
      where('user_goals ? %s' % ApplicationRecord.connection.quote(user_goal))
    }

    before_validation do
      user_goals.reject!(&:blank?)
    end
  end
end
