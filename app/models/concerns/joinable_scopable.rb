module JoinableScopable
  extend ActiveSupport::Concern

  included do
    has_many :join_requests, as: :joinable, dependent: :destroy

    has_many :members, through: :join_requests, source: :user
    has_many :accepted_members, -> { where("join_requests.status = 'accepted'") }, through: :join_requests, source: :user
    has_many :confirmed_members, -> { where("join_requests.status = 'accepted'").where("confirmed_at is not null") }, through: :join_requests, source: :user
    has_many :creators_or_organizers, -> {
      where("join_requests.status = 'accepted'").where("join_requests.role in ('creator', 'organizer')")
    }, through: :join_requests, source: :user

    scope :joined_by, -> (user) {
      where(id: JoinRequest.select(:joinable_id).where(joinable_type: name, user: user, status: JoinRequest::ACCEPTED_STATUS))
    }
    scope :not_joined_by, -> (user) {
      where.not(id: JoinRequest.select(:joinable_id).where(joinable_type: name, user: user, status: JoinRequest::ACCEPTED_STATUS))
    }
    scope :order_by_unread_messages, -> {
      order(Arel.sql("join_requests.unread_messages_count DESC"))
    }

    scope :search_by_member, -> (search) {
      return unless search.present?
      return if search.match?(/\A\d+\z/) # exclude integer

      where(sanitize_sql_array [%(
        %s.id in (
          select joinable_id
          from join_requests
          left join users on users.id = join_requests.user_id
          where
            join_requests.joinable_type = '%s'
            and (lower(users.first_name) ilike '%s' or lower(users.last_name) ilike '%s' or lower(users.phone) ilike '%s')
        )
      ), self.table_name, self.table_name.singularize.camelize, "%#{search.downcase}%", "%#{search.downcase}%", "%#{search.downcase}%"])
    }
  end

  def members_has_changed!
    update_column(:number_of_people, accepted_members.count) if has_attribute?(:number_of_people)
    update_column(:number_of_confirmed_people, confirmed_members.count) if has_attribute?(:number_of_confirmed_people)
  end

  def members_count
    return number_of_people if respond_to?(:number_of_people)

    members.length
  end

  def confirmed_members_count
    return number_of_confirmed_people if respond_to?(:number_of_confirmed_people)

    confirmed_members.length
  end

  def set_forced_join_request_as_member! user
    join_request = user.join_requests.find_by(joinable: self)

    return join_request if join_request.present? && join_request.accepted?

    if join_request.present?
      join_request.status = :accepted
    else
      join_request = JoinRequest.new(joinable: self, user: user, role: :member, status: :accepted)
    end

    join_request.save!
    join_request
  end

  MembershipStruct = Struct.new(:joinable) do
    def initialize(joinable: nil)
      @joinable = joinable
    end

    def stacked_by group = :month
      [
        {
          name: I18n.t("charts.conversations.memberships"),
          data: join_requests_by(group).map { |date, count| [date.to_date.to_s, count] }
        }
      ]
    end

    def join_requests
      @join_requests ||= JoinRequest.where(joinable_type: :Entourage, joinable_id: @joinable.id)
    end

    def join_requests_by group
      join_requests
        .group("DATE_TRUNC('#{group}', created_at)")
        .order(Arel.sql("DATE_TRUNC('#{group}', created_at)"))
        .count
    end
  end

  def membership
    @membership ||= MembershipStruct.new(joinable: self)
  end
end
