module Admin
  class AdminNotesController < Admin::BaseController
    def create
      @notable = find_notable
      @note = @notable.admin_notes.new(note_params)
      @note.author = current_user
      @note.save

      redirect_back fallback_location: admin_actions_path
    end

    def destroy
      note = AdminNote.find(params[:id])
      note.destroy

      redirect_back fallback_location: admin_actions_path
    end

    private

    def find_notable
      raise ActiveRecord::RecordNotFound unless AdminNote::NOTABLE_TYPES.include?(params[:notable_type])

      case params[:notable_type]
      when 'User'
        current_user.community.users.find(params[:notable_id])
      when 'Entourage'
        Entourage.find(params[:notable_id])
      end
    end

    def note_params
      params.require(:admin_note).permit(:body)
    end
  end
end
