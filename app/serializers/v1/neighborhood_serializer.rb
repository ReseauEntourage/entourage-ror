module V1
  class NeighborhoodSerializer < ActiveModel::Serializer
    attributes :id,
      :name,
      :members_count,
      :photo_url,
      :interests,
      :members,
      :ethics,
      :past_events_count,
      :future_events_count,
      :has_ongoing_event

    def interests
      object.interest_list.sort
    end
  end
end
