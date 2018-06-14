module EntourageServices
  class ScoreCalculator
    def initialize(entourage:, user:)
      @entourage = entourage
      @user = user
    end

    def calculate
      EntourageScore.find_or_initialize_by(entourage: entourage, user: user)
          .update(base_score: base_score,
                  final_score: final_score)
    end

    def base_score
      new_user_count = User.where("last_sign_in_at > ?", entourage.created_at).count
      return 0.0 if new_user_count==0
      entourage.members.count.to_f / new_user_count.to_f
    end

    def final_score
      return 0.0 if entourage.status == 'closed'
      return 0.0 if entourage.updated_at < 2.month.ago

      score = appetence_score
      score = origin_score(score)
      score = freshness_score(score)
      score = atd_score(score)
      score
    end

    def appetence_score
      return 0.0 if entourage.category.nil?
      return 0.0 if appetence.nil?

      appetence_category = appetence.send("appetence_#{entourage.category}")
      appetence_sum = appetence.appetence_social + appetence.appetence_mat_help + appetence.appetence_non_mat_help
      result = appetence_category / appetence_sum.to_f
      case entourage.category
        when "mat_help"
          result * 1
        when "non_mat_help"
          result * 1
        when "social"
          result * 1.2
      end
    end

    def origin_score(score)
      user.organization_id==1 ? score * 1.2 : score
    end

    def freshness_score(score)
      return score if user.last_sign_in_at.nil?
      entourage.updated_at > user.last_sign_in_at ? score * 1.2 : score
    end

    def atd_score(score)
      return score unless user.atd_friend?
      entourage.user.atd_friend? ? score * 1.2 : score
    end

    private
    attr_reader :entourage, :user

    def appetence
      user.users_appetence
    end

  end
end
