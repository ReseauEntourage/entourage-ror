class Question < ActiveRecord::Base
  belongs_to :organization

  validates :title, :answer_type, :organization_id, presence: true
  validate :max_question_per_organization

  def max_question_per_organization
    if organization && organization.questions.count >=5
      self.errors.add(:base, "Vous ne pouvez pas ajouter plus de 5 questions pour une association")
    end
  end
end
