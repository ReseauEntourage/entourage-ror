module EntourageServices
  module NeighborhoodAnnouncement
    def self.on_create entourage
      return unless entourage.group_type == 'outing'
      publish_outing_announcement entourage, operation: :created
    end

    def self.on_update entourage
      return unless entourage.group_type == 'outing'
      return unless (entourage.previous_changes.keys & %w(title metadata)).any?
      publish_outing_announcement entourage, operation: :updated
    end

    def self.publish_outing_announcement outing, operation:
      neighborhood_joins = outing.user
        .join_requests.accepted
        .joins(:entourage)
        .merge(Entourage.where(group_type: :neighborhood))
        .includes(:entourage)

      neighborhood_joins.each do |join_request|
        neighborhood = join_request.entourage
        ChatServices::ChatMessageBuilder.new(
          params: {
            message_type: :outing,
            metadata: {
              operation: operation,
              title: outing.title,
              starts_at: outing.metadata[:starts_at],
              display_address: outing.metadata[:display_address],
              uuid: outing.uuid_v2
            }
          },
          user: outing.user,
          joinable: neighborhood,
          join_request: join_request
        )
        .create do |on|
          on.failure do |message|
            Raven.capture_exception(
              ActiveRecord::RecordInvalid.new(message),
              extra: {
                outing: outing.attributes
              }
            )
          end
        end
      end
    end
  end
end
