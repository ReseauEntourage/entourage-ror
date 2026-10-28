module Admin
  class SensitiveWordsController < Admin::BaseController
    before_action :set_word, only: [:edit, :update, :destroy]
    before_action :set_categories, only: [:index, :new, :create, :edit, :update]
    layout 'admin_large'

    def index
      @search = params[:search].presence
      @category = params[:category].presence

      @words = SensitiveWord.order(raw: :asc)
      @words = @words.where(category: @category) if @category
      @words = @words.where('raw ILIKE ?', "%#{@search}%") if @search
      @words = @words.page(params[:page]).per(50)
    end

    def new
      @word = SensitiveWord.new(match_type: 'stem', scope: 'all')
    end

    def create
      @word = SensitiveWord.new(word_params)
      @word.created_by = current_user

      if @word.save
        redirect_to admin_sensitive_words_path, flash: { success: 'Mot sensible créé' }
      else
        render :new
      end
    end

    def edit
    end

    def update
      if @word.update(word_params)
        redirect_to admin_sensitive_words_path, flash: { success: 'Mot sensible mis à jour' }
      else
        render :edit
      end
    end

    def destroy
      @word.destroy
      redirect_to admin_sensitive_words_path, flash: { success: 'Mot sensible supprimé' }
    end

    private

    def set_word
      @word = SensitiveWord.find params[:id]
    end

    def set_categories
      @categories = SensitiveWord.distinct.order(:category).pluck(:category).compact
    end

    def word_params
      params.require(:sensitive_word).permit(:raw, :match_type, :scope, :category)
    end
  end
end
