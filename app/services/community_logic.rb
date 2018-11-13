module CommunityLogic
  def self.for(object)
    community =
      case object
      when Community
        object
      when User, ::Entourage, Tour
        object.community
      else
        Community.new(object)
      end

    Wrapper.new(community.slug)
  end

  def self.debug?
    !Rails.env.production?
  end

  class Wrapper
    def initialize community_slug
      @community_slug = community_slug
      @community_logic =
        begin
          CommunityLogic.const_get(community_slug.camelize, false)
        rescue NameError
          CommunityLogic::Common
        end

      if CommunityLogic.debug? &&
         @community_logic > CommunityLogic::Common
        raise "#{@community_logic.name} must inherit from CommunityLogic::Common"
      end
    end

    def method_missing method, *args
      if @community_logic.respond_to?(method)
        @community_logic.send method, *args
      elsif CommunityLogic.debug?
        Rails.logger.warn "undefined method `#{method}' for #{@community_logic.name}"
      end
    end
  end
end
