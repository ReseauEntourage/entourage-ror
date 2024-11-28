module Admin
  class OpenaiAssistantsController < Admin::BaseController
    layout 'admin_large'

    before_action :set_openai_assistant, only: [:edit, :update]

    def index
      @openai_assistants = OpenaiAssistant.all
        .order(:version)
        .page(page)
        .per(per)
    end

    def edit
    end

    def update
      @openai_assistant.assign_attributes(openai_assistant_params)

      if @openai_assistant.save
        redirect_to edit_admin_openai_assistant_path(@openai_assistant)
      else
        render :edit
      end
    end

    private

    def set_openai_assistant
      @openai_assistant = OpenaiAssistant.find(params[:id])
    end

    def openai_assistant_params
      params.require(:openai_assistant).permit(:prompt, :days_for_actions, :days_for_outings, :poi_from_file, :resource_from_file)
    end

    def page
      params[:page] || 1
    end

    def per
      params[:per] || 25
    end
  end
end
