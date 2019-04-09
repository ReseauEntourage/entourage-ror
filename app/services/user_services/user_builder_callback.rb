module UserServices
  class UserBuilderCallback < Callback
    attr_writer :on_duplicate, :on_invalid_phone_format

    def duplicate(&block)
      @on_duplicate = block
    end

    def invalid_phone_format(&block)
      @on_invalid_phone_format = block
    end

    def on_duplicate(user)
      action_or_failure(@on_duplicate, user)
    end

    def on_invalid_phone_format
      action_or_failure(@on_invalid_phone_format, User.new)
    end
  end
end
