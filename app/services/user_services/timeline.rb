module UserServices
  class Timeline
    attr_accessor :user

    def initialize user
      @user = user
    end

    def get
      (created_entourages + joined_entourages + joined_neighborhoods)
        .sort_by { |item| item[:date] }
        .reverse
    end

    private

    def created_entourages
      user.entourages.where.not(group_type: 'conversation').map do |entourage|
        {
          kind: :created,
          date: entourage.created_at,
          record: entourage,
          label: "A créé « #{entourage.title} »",
        }
      end
    end

    def joined_entourages
      user.join_requests
        .accepted
        .where(joinable_type: 'Entourage')
        .includes(:joinable)
        .map do |join_request|
          entourage = join_request.joinable
          next nil unless entourage

          {
            kind: :joined_entourage,
            date: join_request.created_at,
            record: entourage,
            label: "A rejoint « #{entourage.title} »",
          }
        end.compact
    end

    def joined_neighborhoods
      user.join_requests
        .accepted
        .where(joinable_type: 'Neighborhood')
        .includes(:joinable)
        .map do |join_request|
          neighborhood = join_request.joinable
          next nil unless neighborhood

          {
            kind: :joined_neighborhood,
            date: join_request.created_at,
            record: neighborhood,
            label: "A rejoint le quartier « #{neighborhood.name} »",
          }
        end.compact
    end
  end
end
