module RecommandationServices
  class Completor
    attr_accessor :user, :controller_name, :action_name, :params

    def initialize user:, controller_name:, action_name:, params:
      @user = user
      @controller_name = controller_name
      @action_name = action_name
      @params = params
    end

    def run
      method = "after_#{action_name}".to_sym

      return unless self.class.instance_methods.include?(method)
      return unless matched_user_recommandations = send(method, controller_name.singularize, params)

      matched_user_recommandations.update_all(completed_at: Time.now)
    end

    def after_index instance_type
      user_recommandations.where(instance_type: instance_type, action: :index)
    end

    # @caution does not work with webviews
    def after_show instance_type, params
      user_recommandations.where(instance_type: instance_type, action: :show, instance_id: params[:id])
    end

    def after_create instance_type
      user_recommandations.where(instance_type: instance_type, action: :create)
    end

    private

    def user_recommandations
      @user_recommandations ||= user.user_recommandations.active
    end
  end
end
