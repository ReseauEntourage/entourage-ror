module Reactionnable
  extend ActiveSupport::Concern

  included do
    has_many :chat_message_reactions # using view for summary
    has_many :user_reactions, as: :instance # using table for details
  end

  class_methods do
    # Single grouped query for a list of instances, instead of relying on each
    # instance's :user_reactions association being preloaded (fragile: any `.where`
    # on the association bypasses the preload and re-hits the DB per instance).
    def reaction_ids_by_message(instances, user)
      return {} unless user

      instance_ids = instances.map(&:id)
      return {} if instance_ids.empty?

      UserReaction.where(instance_type: name, instance_id: instance_ids, user_id: user.id)
        .pluck(:instance_id, :reaction_id).to_h
    end
  end

  ReactionsStruct = Struct.new(:instance) do
    def initialize(instance: nil)
      @instance = instance
    end

    def summary
      @instance.chat_message_reactions
    end

    def user_reaction_id user_id
      # `.where` on an already-preloaded association still hits the DB, so when the
      # caller preloaded :user_reactions (list endpoints), filter in memory instead.
      if @instance.user_reactions.loaded?
        @instance.user_reactions.find { |user_reaction| user_reaction.user_id == user_id }&.reaction_id
      else
        @instance.user_reactions.where(user_id: user_id).pluck(:reaction_id).first
      end
    end

    def build user:, reaction_id:
      @instance.user_reactions.build(user: user, reaction_id: reaction_id)
    end

    def destroy user:
      return unless user_reaction = @instance.user_reactions.find_by(user: user)

      user_reaction.destroy and return user_reaction.reaction_id
    end
  end

  def reactions
    ReactionsStruct.new(instance: self)
  end
end
