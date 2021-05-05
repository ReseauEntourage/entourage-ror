class QuestionsController < ApplicationController
  before_action :authenticate_manager!

  def create
    question = @current_user.organization.questions.build(question_params)
    if question.save
      redirect_to edit_organization_path(@current_user.organization), notice: "La question a bien été ajouté"
    else
      redirect_to edit_organization_path(@current_user.organization), alert: "La question n'a pas été ajouté, vérifier les valeurs saisies"
    end
  end

  def destroy
    Question.find(params[:id]).destroy
    redirect_to edit_organization_path(@current_user.organization), notice: "La question a bien été supprimé"
  end

  private

  def question_params
    params.require(:question).permit(:title, :answer_type, :answer_value)
  end
end
