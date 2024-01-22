module Reactionnable
  extend ActiveSupport::Concern

  included do
    has_many :chat_message_reactions
    has_many :user_reactions, as: :instance
  end

  ReactionsStruct = Struct.new(:instance) do
    def initialize(instance: nil)
      @instance = instance
    end

    def summary
      @instance.chat_message_reactions
    end

    def user_ids_for_reaction_id reaction_id
      @instance.user_reactions.where(reaction_id: reaction_id).pluck(:user_id)
    end

    def user_has_reacted? user_id
      @instance.user_reactions.where(user_id: user_id).exists?
    end

    def build user:, reaction_id:
      @instance.user_reactions.build(user: user, reaction_id: reaction_id)
    end

    def destroy user:
      return unless user_reaction = @instance.user_reactions.find_by(user: user)

      user_reaction.destroy
    end
  end

  def reactions
    ReactionsStruct.new(instance: self)
  end
end
