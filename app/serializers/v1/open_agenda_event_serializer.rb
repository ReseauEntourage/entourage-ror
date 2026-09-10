module V1
  class OpenAgendaEventSerializer < ActiveModel::Serializer
    attribute :id
    attribute :title
    attribute :description
    attribute :starts_at
    attribute :ends_at
    attribute :location
    attribute :is_free
    attribute :organizer_name
  end
end
