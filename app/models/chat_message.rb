require 'experimental/jsonb_with_schema'

class ChatMessage < ActiveRecord::Base
  include FeedsConcern

  belongs_to :messageable, polymorphic: true, touch: true
  belongs_to :user

  before_validation :generate_content

  validates :messageable_id, :messageable_type, :content, :user_id, presence: true
  validates_inclusion_of :message_type, in: -> (m) { m.message_types }
  validates :metadata, schema: -> (m) { "#{m.message_type}:metadata" }

  scope :ordered, -> { order("created_at DESC") }

  attribute :metadata, Experimental::JsonbWithSchema.new

  def self.json_schema urn
    JsonSchemaService.base do
      case urn
      when 'visit:metadata'
        {
          visited_at: { format: 'date-time-iso8601' }
        }
      when 'outing:metadata'
        {
          operation: { type: :string, enum: [:created, :updated] },
          title: { type: :string },
          starts_at: { format: 'date-time-iso8601' },
          display_address: { type: :string },
          uuid: { type: :string }
        }
      when 'status_update:metadata'
        {
          status: { type: :string },
          outcome_success: { type: :boolean }
        }
      end
    end
  end

  def message_types
    @message_types ||= ['status_update', *messageable&.group_type_config&.dig('message_types')]
  end

  private

  def generate_content
    self.content = generated_content
  rescue => e
    errors.add(:content, e.message)
  end

  def generated_content
    case message_type
    when 'visit' then visit_content
    when 'outing' then outing_content
    when 'status_update' then status_update_content
    else content
    end
  end

  def visit_content
    date = Time.zone.parse(metadata[:visited_at]).to_date
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
        messageable.metadata[:visited_user_first_name],
        date_expr
      ].join(' ')
    end
  end

  def outing_content
    action = {
      created: 'a créé',
      updated: 'a modifié'
    }[metadata[:operation].to_sym]
    name = {
      pfp: 'une sortie'
    }[messageable.community.slug.to_sym] || 'un évènement'
    starts_at = Time.zone.parse(metadata[:starts_at])
    [
      "#{action} #{name} :",
      metadata[:title],
      I18n.l(starts_at, format: "le %d/%m à %Hh%M,"),
      metadata[:display_address]
    ].join("\n")
  end

  def status_update_content
    "a clôturé #{GroupService.name messageable, :l}"
  end
end
