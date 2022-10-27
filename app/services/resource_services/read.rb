module ResourceServices
  class Read
    attr_reader :resource, :user

    def initialize resource:, user:
      @resource = resource
      @user = user
    end

    def set_as_watched
      user_resource = UsersResource.find_by_resource_id_and_user_id(resource.id, user.id)

      return user_resource if user_resource.present? && user_resource.watched?

      if user_resource.present?
        user_resource.watched = true
      else
        user_resource = UsersResource.new(resource: resource, user: user, watched: true)
      end

      user_resource
    end

    def set_as_watched_and_save
      set_as_watched.save
    end
  end
end
