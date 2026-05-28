module Admin
  class NotificationsController < Admin::BaseController
    # POST /admin/notifications — démonstration ActionCable
    # Diffuse un message temps réel à l'admin connecté via WebSocket.
    def create
      NotificationChannel.broadcast_to_user(current_admin, {
        message: params[:message].presence || "Notification de test",
        type:    params[:type].presence || "info"
      })

      respond_to do |format|
        format.json { render json: { status: "broadcasted" }, status: :ok }
        format.html { redirect_back(fallback_location: root_path, notice: "Notification envoyée") }
      end
    end
  end
end
