module EntourageServices
  class UsersAppetenceBuilder
    delegate :entourages, :join_requests, to: :user

    APPETENCE_MULTIPLIER = 10
    APPETENCE_DEFAULT_DISTANCE = 150

    def initialize(user:)
      @user = user
    end

    def create
      new_user_appetence = UsersAppetence.find_or_initialize_by(user: user)
      new_user_appetence.update!(user: user,
                             appetence_social: appetence_social,
                             appetence_mat_help: appetence_mat_help,
                             appetence_non_mat_help: appetence_non_mat_help,
                             avg_dist: avg_dist)
      new_user_appetence
    end

    def view_entourage(entourage:)
      update(entourage: entourage, bonus: 1)
    end

    def join_entourage(entourage:)
      update(entourage: entourage, bonus: 10)
    end

    private
    attr_reader :user

    def update(entourage:, bonus:)
      hash = {
          social: user_appetence.appetence_social || 0,
          mat_help: user_appetence.appetence_mat_help || 0,
          non_mat_help: user_appetence.appetence_non_mat_help || 0,
      }
      hash[entourage.category.to_sym] += bonus if entourage.category
      user_appetence.update!(appetence_social: hash[:social],
                             appetence_mat_help: hash[:mat_help],
                             appetence_non_mat_help: hash[:non_mat_help],
                             avg_dist: avg_dist)
    end

    def user_appetence
      @user_appetence ||= UsersAppetence.find_or_initialize_by(user: user)
    end

    def appetence_social
      entourages.social_category.count * APPETENCE_MULTIPLIER
    end

    def appetence_mat_help
      entourages.mat_help_category.count * APPETENCE_MULTIPLIER
    end

    def appetence_non_mat_help
      entourages.non_mat_help_category.count * APPETENCE_MULTIPLIER
    end

    def avg_dist
      join_requests.average(:distance) || APPETENCE_DEFAULT_DISTANCE
    end
  end
end
