module Bertable
  extend ActiveSupport::Concern

  included do
    after_save :bert_on_save, :if => :bertable_field_changed?

    has_one :lexical_transformation, as: :instance
  end

  def bertable_field_changed?
    previous_changes.slice(:title, :name, :description).present?
  end

  def bert
    @bert ||= BertStruct.new(instance: self)
  end

  def bert_on_save
    bert.on_save
  end

  def self.bert_concatenated_fields_for instance
    bert_fields_for(instance).map { |field| instance.send(field) }.join(' ')
  end

  def self.bert_fields_for instance
    return [:title, :description] if instance.is_a?(Entourage)

    [:name, :description]
  end

  BertStruct = Struct.new(:instance) do
    def initialize(instance: nil)
      @instance = instance
    end

    def on_save
      ensure_lexical_transformation_exists!
    end

    def ensure_lexical_transformation_exists!
      return if @instance.lexical_transformation && @instance.lexical_transformation.persisted?

      (@instance.lexical_transformation || @instance.build_lexical_transformation).save!
    end

    def similars
      return [] unless @instance.lexical_transformation.present?
      return [] unless @instance.lexical_transformation.vectors.present?

      exclude_conditions = if @instance.is_a?(Entourage)
        <<-SQL
          AND (lm.instance_type != 'Entourage' OR lm.instance_id in (
            select id
            from entourages
            where
              group_type = 'action'
              and entourage_type != '#{@instance.entourage_type}'
              and status = 'open'
          ))
        SQL
      else
        ''
      end

      query = <<-SQL
        SELECT lm.id,
           cosine_similarity(
             jsonb_to_float8_array(lm.vectors::text),
             jsonb_to_float8_array(q.vectors::text)
           ) AS similarity_score,
           instance_type,
           instance_id
        FROM lexical_transformations lm,
          (SELECT vectors FROM lexical_transformations WHERE vectors is not null and instance_type = '#{@instance.class.base_class.name}' and instance_id = #{@instance.id}) q
        WHERE lm.vectors IS NOT NULL
          AND (lm.instance_type != '#{@instance.class.base_class.name}' OR lm.instance_id != #{@instance.id})

          #{exclude_conditions}
        ORDER BY similarity_score DESC
        LIMIT 10
      SQL

      LexicalTransformation.find_by_sql(query)
    end
  end
end
