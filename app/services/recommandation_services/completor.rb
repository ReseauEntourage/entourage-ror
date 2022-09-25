module RecommandationServices
  class Completor
    attr_accessor :user, :instance, :action_name, :params

    def initialize user:, controller_name:, action_name:, params:
      @user = user
      @instance = controller_name.singularize.to_sym
      @action_name = action_name.to_sym
      @params = params
    end

    def run
      return unless Recommandation::INSTANCES.include?(instance)
      return unless Recommandation::ACTIONS.include?(action_name)

      method = "after_#{action_name}".to_sym

      return unless self.class.instance_methods.include?(method)
      return unless matched_user_recommandations = send(method, instance, params)

      matched_user_recommandations.update_all(completed_at: Time.now)
    end

    def after_index instance, params
      user_recommandations.for_instance(instance).where(action: :index)
    end

    # @caution does not work with webviews
    def after_show instance, params
      user_recommandations.for_instance(instance).where(action: :show, instance_id: params[:id])
    end

    def after_create instance, params
      return after_create_user(params) if instance == :user

      user_recommandations.for_instance(instance).where(action: :create)
    end

    def after_create_user params
      return after_create_user_on_neighborhood if params.has_key?(:neighborhood_id)
      return after_create_user_on_outing if params.has_key?(:outing_id)
    end

    def after_create_user_on_outing
      user_recommandations.for_instance(:outing).where(action: :join)
    end

    def after_create_user_on_neighborhood
      user_recommandations.for_instance(:neighborhood).where(action: :join)
    end

    private

    def user_recommandations
      @user_recommandations ||= user.user_recommandations.active
    end
  end
end
