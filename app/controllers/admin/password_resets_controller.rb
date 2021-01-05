module Admin
  class PasswordResetsController < Admin::BaseController
    layout "login"
    skip_before_action :authenticate_admin!

    def new
    end

    def create
      if params[:phone].blank?
        return render json: { error: 'Le numéro de téléphone doit être renseigné' }
      end

      phone = Phone::PhoneBuilder.new(phone: params[:phone]).format
      user = User.find_by(phone: phone)

      if user.present?
        user.generate_admin_password_token!
        AdminMailer.forgot_password(user: user).deliver_now
        flash[:notice] = 'Un mail vient de vous être envoyé avec les instructions de réinitialisation'
      else
        flash[:error] = 'Identifiant incorrect'
      end
        redirect_to new_admin_password_reset_path
    end

    def edit
      @user = User.find_by_reset_admin_password_token!(params[:id])
    rescue
      flash[:error] = "Le lien n'est pas valide ou a expiré. Merci de générer un nouveau lien"
      redirect_to new_admin_session_path
    end

    def update
      token = params[:token].to_s

      if params[:email].blank?
        return render json: { error: 'Token not present' }
      end

      user = User.find_by(reset_admin_password_token: token)

      if user.present? && user.admin_password_token_valid?
        if user.reset_admin_password!(params[:admin_password])
          render json: { status: 'ok' }, status: :ok
        else
          render json: { error: user.errors.full_messages }, status: :unprocessable_entity
        end
      else
        render json: { error:  ['Link not valid or expired. Try generating a new link.'] }, status: :not_found
      end
    end
  end
end