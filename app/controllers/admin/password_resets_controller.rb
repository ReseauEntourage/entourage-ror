module Admin
  class PasswordResetsController < Admin::BaseController
    layout 'login'
    skip_before_action :authenticate_admin!

    def new
    end

    def create
      if params[:phone].blank?
        return render json: { error: 'Le numéro de téléphone doit être renseigné' }
      end

      phone = Phone::PhoneBuilder.new(phone: params[:phone]).format
      user = User.find_by(phone: phone)

      if user.nil?
        flash[:error] = 'Identifiant incorrect'
      elsif !user.email
        flash[:error] = 'Le compte associé au téléphone doit définir un email'
      elsif !user.admin
        flash[:error] = 'Votre profil doit être admin'
      elsif user.generate_admin_password_token.save
        AdminMailer.forgot_password(user: user).deliver_now
        flash[:notice] = 'Un mail vient de vous être envoyé avec les instructions de réinitialisation'
        redirect_to new_admin_session_path and return
      else
        flash[:error] = user.errors.full_messages.to_sentence
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
      token = params[:id].to_s

      @user = User.find_by(reset_admin_password_token: token)

      # token validation
      unless @user.present? && @user.admin_password_token_valid?
        flash[:error] = "Le lien n'est pas valide ou a expiré. Merci de générer un nouveau lien"
        redirect_to new_admin_session_path and return
      end

      @user.assign_attributes(user_params)

      # form and reset validation
      if @user.valid? && @user.reset_admin_password!
        flash[:notice] = 'Votre mot de passe a été mis à jour.'
        redirect_to new_admin_session_path
      else
        flash[:error] = @user.errors.full_messages.to_sentence
        redirect_to edit_admin_password_reset_path(params[:id])
      end
    end

    private
    def user_params
      params.require(:user).permit(:admin_password, :admin_password_confirmation)
    end
  end
end