module RecommandationServices
  class User
    OBSOLETE_PERIOD = 15.days

    attr_accessor :user

    def initialize user
      @user = user
    end

    def initiate
      skip_obsolete_user_recommandations

      return if has_all_recommandations?

      Recommandation::FRAGMENTS.each do |fragment|
        next if user_fragments.include?(fragment)

        # create new user_recommandation based on recommandations
        successes = Recommandation.fragment(fragment).for_profile(profile).recommandable_for(user).each do |recommandation|
          next if recommandation.matches(user_recommandations_orphan)

          break true if instanciate_user_recommandation_from_recommandation(recommandation).save
        end

        # create new user_recommandation based on contributions, solicitations, outings or neighborhoods
        unless successes.compact.any
          instanciate_local_user_recommandation_for_fragment(fragment).save
        end
      end
    end

    def skip_obsolete_user_recommandations
      user.user_recommandations.active.each do |user_recommandation|
        user_recommandation.update_attribute(:skipped_at, Time.now) if user_recommandation.created_at < OBSOLETE_PERIOD.ago
      end
    end

    def instanciate_user_recommandation_from_recommandation recommandation
      user_recommandation = UserRecommandation.new(
        user: user,
        recommandation: recommandation,
        name: recommandation.name,
        image_url: recommandation.image_url,
        instance: recommandation.instance,
        action: recommandation.action,
        fragment: recommandation.fragment
      )

      klass = "finder_#{recommandation.action}".classify

      return user_recommandation unless method_exists?(klass, :find_identifiant)

      user_recommandation.identifiant = call_method(klass, :find_identifiant, user, recommandation)
      user_recommandation
    end

    def instanciate_local_user_recommandation_for_fragment fragment
      return unless outing = Outing
        .not_joined_by(user)
        .inside_perimeter(user.address.latitude, user.address.longitude, user.travel_distance)
        .order_by_distance_from
        .first

      UserRecommandation.new(
        user: user,
        name: outing.title,
        image_url: outing.image_url,
        instance: :outing,
        action: :show,
        fragment: fragment
      )
    end

    private

    def user_fragments
      @user_fragments ||= user.recommandations.pluck(:fragment).compact.uniq.sort
    end

    def user_recommandations_orphan
      @user_recommandations_orphan ||= user.user_recommandations.orphan.as_json(only: [:action, :instance, :instance_id, :instance_url])
    end

    def has_all_recommandations?
      user_fragments.sort == Recommandation::FRAGMENTS.sort
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
