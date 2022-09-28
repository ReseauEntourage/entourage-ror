module RecommandationServices
  class User
    OBSOLETE_PERIOD = 15.days

    attr_accessor :user

    def initialize user
      @user = user
    end

    def initiate
      skip_obsolete_recommandations

      return if has_all_recommandations?

      Recommandation::FRAGMENTS.each do |fragment|
        next if user_fragments.include?(fragment)

        Recommandation.fragment(fragment).for_profile(profile).recommandable_for(user).each do |recommandation|
          break if instanciate_user_recommandation_from_recommandation(recommandation).save
        end
      end
    end

    def recommandations
      user.user_recommandations.active
    end

    def skip_obsolete_recommandations
      recommandations.each do |recommandation|
        recommandation.update_attribute(:skipped_at, Time.now) if recommandation.created_at < OBSOLETE_PERIOD.ago
      end
    end

    def instanciate_user_recommandation_from_recommandation recommandation
      user_recommandation = UserRecommandation.new(user: user, recommandation: recommandation)
      user_recommandation.name = recommandation.name
      user_recommandation.image_url = recommandation.image_url
      user_recommandation.instance = recommandation.instance
      user_recommandation.action = recommandation.action

      klass = "finder_#{recommandation.action}".classify

      return user_recommandation unless method_exists?(klass, :find_identifiant)

      user_recommandation.identifiant = call_method(klass, :find_identifiant, user, recommandation)
      user_recommandation
    end

    private

    def user_fragments
      @user_fragments ||= user.recommandations.pluck(:fragment).compact.uniq.sort
    end

    def has_all_recommandations?
      user_fragments == Recommandation::FRAGMENTS.sort
    end

    def profile
      @profile ||= (user.is_ask_for_help? ? :ask_for_help : :offer_help)
    end

    def method_exists? klass, method
      RecommandationServices.const_get(klass).methods.include?(method)

      true
    rescue NameError
      false
    end

    def call_method klass, method, user, recommandation
      RecommandationServices.const_get(klass).send(method, user, recommandation)
    rescue
      nil
    end
  end
end
