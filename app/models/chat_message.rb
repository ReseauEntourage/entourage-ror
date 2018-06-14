class ChatMessage < ActiveRecord::Base
  include FeedsConcern

  belongs_to :messageable, polymorphic: true, touch: true
  belongs_to :user

  before_validation :generate_content

  validates :messageable_id, :messageable_type, :content, :user_id, presence: true
  validates_inclusion_of :message_type, in: -> (m) { m.messageable&.group_type_config&.dig('message_types') || [] }
  validates :metadata, schema: :metadata_schema

  scope :ordered, -> { order("created_at DESC") }

  private

  def generate_content
    self.content = generated_content
  rescue => e
    errors.add(:content, e.message)
  end

  def generated_content
    case message_type
    when 'visit' then visit_content
    else content
    end
  end

  def visit_content
    date = Time.zone.parse(metadata['visited_at']).to_date
    date_expr =
      case Time.zone.today - date
      when 0 then "aujourd'hui"
      when 1 then "hier"
      else I18n.l date, format: "le %-d %B"
      end

    if user.roles.include? :visited
      [
        (date.future? ? "Je serai" : "J'ai été"),
        "voisiné(e)",
        date_expr
      ].join(' ')
    else
      [
        (date.future? ? "Je voisinerai" : "J'ai voisiné"),
        messageable.metadata['visited_user_first_name'],
        date_expr
      ].join(' ')
    end
  end

  def metadata_schema
    schema = {
      type: :object,
      additionalProperties: false
    }

    schema[:properties] =
      case message_type
      when 'visit'
        {
          visited_at: { format: 'date-time-iso8601' }
        }
      else
        {}
      end

    schema[:required] ||= schema[:properties].keys if schema[:properties].any?

    schema
  end
end
