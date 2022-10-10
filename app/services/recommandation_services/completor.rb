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
      return unless instances_list.include?(instance)
      return unless actions_list.include?(action_name)

      method = "after_#{action_name}".to_sym

      return unless self.class.instance_methods.include?(method)
      return unless criteria = send(method, instance, params)

      set_completed_notification! criteria
      set_completed_criteria! criteria
      log_completed_criteria! criteria
    end

    def after_index instance, params
      { instance: instance, action: :index }
    end

    def after_show instance, params
      return after_show_webview(params) if instance == :webview

      { instance: instance, action: :show, instance_id: params[:id] }
    end

    def after_show_webview params
      { instance: :webview, action: :show, instance_url: params[:url] }
    end

    def after_create instance, params
      return after_create_user(params) if instance == :user

      { instance: instance, action: :create }
    end

    def after_create_user params
      return after_create_user_on_neighborhood if params.has_key?(:neighborhood_id)
      return after_create_user_on_outing if params.has_key?(:outing_id)
      return after_create_user_on_resource(params) if params.has_key?(:resource_id)
    end

    def after_create_user_on_outing
      { instance: :outing, action: :join }
    end

    def after_create_user_on_neighborhood
      { instance: :neighborhood, action: :join }
    end

    def after_create_user_on_resource params
      { instance: :resource, action: :show, instance_id: params[:resource_id] }
    end

    protected

    def set_completed_notification! criteria
      UserNotification
        .active_criteria_by_user(user, criteria)
        .update_all(completed_at: Time.now)
    end

    def set_completed_criteria! criteria
      UserRecommandation
        .active_criteria_by_user(user, criteria)
        .update_all(completed_at: Time.now)
    end

    def log_completed_criteria! criteria
      return if UserRecommandation.processed_criteria_by_user(user, criteria).any?

      UserRecommandation.new(criteria.merge(user: user, completed_at: Time.now)).save
    end

    private

    def instances_list
      Recommandation::INSTANCES + UserNotification::INSTANCES
    end

    def actions_list
      Recommandation::ACTIONS + UserNotification::ACTIONS
    end
  end
end
