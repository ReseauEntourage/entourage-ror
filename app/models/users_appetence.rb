class UsersAppetence < ApplicationRecord
  belongs_to :user
  validates :appetence_social,
            :appetence_mat_help,
            :appetence_non_mat_help,
            :avg_dist, presence: true

  validates_uniqueness_of :user_id
end
