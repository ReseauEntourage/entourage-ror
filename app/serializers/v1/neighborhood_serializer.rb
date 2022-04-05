module V1
  class NeighborhoodSerializer < ActiveModel::Serializer
    attributes :id,
      :name,
      :description,
      :welcome_message,
      :members_count,
      :image_url,
      :interests,
      :members,
      :ethics,
      :past_outings_count,
      :future_outings_count,
      :has_ongoing_outing

    def interests
      object.interest_list.sort
    end

    def has_ongoing_outing
      object.has_ongoing_outing?
    end
  end
end
