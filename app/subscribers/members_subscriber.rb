class MembersSubscriber
  def members_changed event
    object = event.payload[:object]

    SmalltalkServices::Messager.new(object, :update) if object.is_a?(Smalltalk)
  end
end
