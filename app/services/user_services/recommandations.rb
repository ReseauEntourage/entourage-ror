module UserServices
  class Recommandations
    def initialize user
      @user = user
    end

    # name
    # type (instance)
    # action (crud)
    # id (id, path, uuid) => params: { id: nil, uuid: nil, url: nil }
    # image_url
    def find
      [
        {
          name: :profile_show,
          type: :profile,
          action: :show,
          image_url: nil,
          params: { id: nil, uuid: nil, url: nil}
        },
        {
          name: :neighborhood_show,
          type: :neighborhood,
          action: :show,
          image_url: nil,
          params: { id: neighborhood&.id, uuid: nil, url: nil}
        },
        {
          name: :neighborhood_index,
          type: :neighborhood,
          action: :index,
          image_url: nil,
          params: { id: nil, uuid: nil, url: nil}
        },
        {
          name: :neighborhood_new,
          type: :neighborhood,
          action: :new,
          image_url: nil,
          params: { id: nil, uuid: nil, url: nil}
        },
        {
          name: :outing_index,
          type: :outing,
          action: :index,
          image_url: nil,
          params: { id: nil, uuid: nil, url: nil}
        },
        {
          name: :outing_show,
          type: :outing,
          action: :show,
          image_url: nil,
          params: { id: outing&.id, uuid: nil, url: nil}
        },
        {
          name: :resource_index,
          type: :resource,
          action: :index,
          image_url: nil,
          params: { id: nil, uuid: nil, url: nil}
        },
        # {
        #   name: :resource_show,
        #   type: :resource
        #   action: :show,
        #   image_url: nil,
        #   params: { id: resource.id, uuid: nil, url: nil}
        #  },
        # {
        #   name: :webview_show,
        #   type: :webview
        #   action: :show,
        #   image_url: nil,
        #   params: { id: nil, uuid: nil, url: webview.path}
        #  },
        {
          name: :conversation_show,
          type: :conversation,
          action: :show,
          image_url: nil,
          params: { id: nil, uuid: conversation&.uuid, url: nil}
        },
        {
          name: :contribution_index,
          type: :contribution,
          action: :index,
          image_url: nil,
          params: { id: nil, uuid: nil, url: nil}
        },
        {
          name: :ask_for_help_index,
          type: :ask_for_help,
          action: :index,
          image_url: nil,
          params: { id: nil, uuid: nil, url: nil}
        },
        {
          name: :contribution_show,
          type: :contribution,
          action: :show,
          image_url: nil,
          params: { id: contribution&.id, uuid: nil, url: nil}
        },
        {
          name: :ask_for_help_show,
          type: :ask_for_help,
          action: :show,
          image_url: nil,
          params: { id: ask_for_help&.id, uuid: nil, url: nil}
        },
        {
          name: :ask_for_help_new,
          type: :ask_for_help,
          action: :new,
          image_url: nil,
          params: { id: nil, uuid: nil, url: nil}
        },
        {
          name: :poi_index,
          type: :poi,
          action: :index,
          image_url: nil,
          params: { id: nil, uuid: nil, url: nil}
        },
        {
          name: :poi_show,
          type: :poi,
          action: :index,
          image_url: nil,
          params: { id: poi&.id, uuid: nil, url: nil}
        },
      ]
    end

    def neighborhood
      Neighborhood.last
    end

    def outing
      Entourage.where(group_type: :outing).last
    end

    def resource
      # Resource.last
    end

    def webview
      # Webview.last
    end

    def poi
      Poi.last
    end

    def conversation
      Entourage.where(group_type: :conversation).last
    end

    def contribution
      Entourage.contributions.last
    end

    def ask_for_help
      Entourage.ask_for_helps.last
    end
  end
end
