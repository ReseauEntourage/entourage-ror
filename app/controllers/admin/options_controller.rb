module Admin
  class OptionsController < Admin::BaseController
    before_action :authenticate_super_admin!

    layout 'admin_large'

    def index
      @options = Option.all
    end

    def update
      @option = Option.find(params[:id])
      @option.assign_attributes(option_params)

      if @option.save
        flash[:notice] = "L'option #{@option.key} est maintenant %s" % (@option.active? ? 'active' : 'inactive')
      else
        flash[:error] = @option.errors.full_messages.to_sentence
      end

      redirect_to admin_options_path
    end

    private
    def option_params
      params.require(:option).permit(:active)
    end
  end
end
