module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      user_id = user_id_from_token || cookies.signed[:user_id]
      User.find_by(id: user_id) || reject_unauthorized_connection
    end

    # Token signé généré par ApplicationController#cable_auth_token, passé via meta tag
    def user_id_from_token
      token = request.params[:token]
      return nil if token.blank?
      Rails.application.message_verifier(:cable).verify(token)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end
  end
end
