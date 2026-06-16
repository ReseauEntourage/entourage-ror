class RouteCompletionJob
  include Sidekiq::Worker

  sidekiq_options retry: false, queue: :default

  def perform(user_id, controller_name, action_name, params)
    user = User.find_by(id: user_id)
    return unless user

    RouteCompletionService.new(
      user: user,
      controller_name: controller_name,
      action_name: action_name,
      params: ActionController::Parameters.new(params)
    ).run
  end
end
