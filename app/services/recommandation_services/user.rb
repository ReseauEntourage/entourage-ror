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
        initiate_fragment(fragment)
      end
    end

    def initiate_fragment fragment
      return if user_fragments.include?(fragment)

      Recommandation.recommandable_for_user_and_fragment(user, fragment).each do |recommandation|
        next if recommandation.matches(user_recommandations_orphan)

        return if create_user_recommandation_from_recommandation(recommandation)
      end

      # create new user_recommandation based on contributions, solicitations, outings or neighborhoods
      create_local_user_recommandation_for_fragment(fragment)
    end

    def skip_obsolete_user_recommandations
      user.user_recommandations.active.each do |user_recommandation|
        user_recommandation.update_attribute(:skipped_at, Time.now) if user_recommandation.created_at < OBSOLETE_PERIOD.ago
      end
    end

    def create_user_recommandation_from_recommandation recommandation
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
      user_recommandation.save
    end

    def create_local_user_recommandation_for_fragment fragment
      preferred_instance = Recommandation.preferred_instance_for_user_and_fragment(user, fragment)

      return unless preferred_instance
      return unless preferred_instance.respond_to?(:closests_recommandable_to)
      return unless record = preferred_instance.closests_recommandable_to(user).first

      UserRecommandation.new(
        user: user,
        name: record.title,
        image_url: record.image_url,
        instance: record.class.name.underscore,
        instance_id: record.id,
        action: :show,
        fragment: fragment
      ).save
    end

    private

    def user_fragments
      @user_fragments ||= user.user_recommandations.active.pluck(:fragment).compact.uniq.sort
    end

    def user_recommandations_orphan
      @user_recommandations_orphan ||= user.user_recommandations.orphan.as_json(only: [:action, :instance, :instance_id, :instance_url])
    end

    def has_all_recommandations?
      user_fragments.sort == Recommandation::FRAGMENTS.sort
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
