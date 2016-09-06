module UserServices
  class UserBuilderCallback < Callback
    attr_accessor :on_duplicate

    def duplicate(&block)
      @on_duplicate = block
    end
  end
end