class Encounter < ActiveRecord::Base

	belongs_to :user

  def to_s
    "#{id} - Entre #{user.first_name} et #{street_person_name}"
  end
end
