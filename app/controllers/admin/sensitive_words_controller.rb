module Admin
  class SensitiveWordsController < Admin::BaseController
    before_filter :set_word
    layout 'admin_large'

    def destroy
      @word.destroy
      redirect_to admin_entourages_path
    end

    private

    def set_word
      @word = SensitiveWord.find params[:id]
    end
  end
end
