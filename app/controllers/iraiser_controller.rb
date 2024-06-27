class IraiserController < ActionController::Base
  # deprecated on a iraiser hook
  # @see https://entourage.iraiser.eu/manager.php/manager/settings_push/edit on webhook
  def notification
    return head :ok
  end
end
