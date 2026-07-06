class UserReaction < ApplicationRecord
  include PublishesEvents

  belongs_to :user
  belongs_to :reaction
  belongs_to :instance, polymorphic: true

  validates_uniqueness_of :user_id, scope: [:instance_id, :instance_type], message: 'You can only react once'


  def entourage?
    return false unless instance.respond_to?(:entourage?)

    instance.entourage?
  end

  def outing?
    return false unless instance.respond_to?(:outing?)

    instance.outing?
  end

  def papotage?
    return false unless instance.respond_to?(:papotage?)

    instance.papotage?
  end

  def conversation?
    return false unless instance.respond_to?(:conversation?)

    instance.conversation?
  end

  def neighborhood?
    return false unless instance.respond_to?(:neighborhood?)

    instance.neighborhood?
  end

  def smalltalk?
    return false unless instance.respond_to?(:smalltalk?)

    instance.smalltalk?
  end
end
