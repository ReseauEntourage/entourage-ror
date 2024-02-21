module Reactionnable
  extend ActiveSupport::Concern

  included do
    has_many :chat_message_reactions # using view for summary
    has_many :user_reactions, as: :instance # using table for details
  end

  ReactionsStruct = Struct.new(:instance) do
    def initialize(instance: nil)
      @instance = instance
    end

    def summary
      @instance.chat_message_reactions
    end

    def user_reaction_id user_id
      # @instance.user_reactions.where(user_id: user_id).pluck(:reaction_id).first
      return unless matched = @instance.user_reactions.pluck(:user_id, :reaction_id).find do |id, _|
        id == user_id
      end

      matched.last
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
