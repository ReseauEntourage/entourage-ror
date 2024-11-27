module Admin
  class OpenaiAssistantConfigurationsController < Admin::BaseController
    layout 'admin_large'

    before_action :set_openai_assistant_configuration, only: [:edit, :update]

    def index
      @openai_assistant_configurations = OpenaiAssistantConfiguration.all
        .order(:version)
        .page(page)
        .per(per)
    end

    def edit
    end

    def update
      @openai_assistant_configuration.assign_attributes(openai_assistant_configuration_params)

      if @openai_assistant_configuration.save
        redirect_to edit_admin_openai_assistant_configuration_path(@openai_assistant_configuration)
      else
        render :edit
      end
    end

    private

    def set_openai_assistant_configuration
      @openai_assistant_configuration = OpenaiAssistantConfiguration.find(params[:id])
    end

    def openai_assistant_configuration_params
      params.require(:openai_assistant_configuration).permit(:prompt, :days_for_actions, :days_for_outings, :poi_from_file, :resource_from_file)
    end

    def page
      params[:page] || 1
    end

    def per
      params[:per] || 25
    end
  end
end
