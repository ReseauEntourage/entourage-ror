# this module handles contributions and solicitations matchings using bert vectors
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

  BertStruct = Struct.new(:instance) do
    def initialize(instance: nil)
      @instance = instance
    end

    def on_save
      ensure_lexical_transformation_exists!

      @instance.lexical_transformation.vectorizes
    end

    def ensure_lexical_transformation_exists!
      return if @instance.lexical_transformation && @instance.lexical_transformation.persisted?

      (@instance.lexical_transformation || @instance.build_lexical_transformation).save!
    end

    def similars
      # add/remove "AND lm.instance_type = '#{@instance.class.base_class.name}'" whenever we want matchings against different models
      query = <<-SQL
        SELECT lm.id,
           cosine_similarity(
             jsonb_to_float8_array(lm.name::text),
             jsonb_to_float8_array(q.name::text)
           ) AS similarity_score,
           instance_type,
           instance_id
        FROM lexical_transformations lm,
             (SELECT name FROM lexical_transformations WHERE performed = true and instance_type = '#{@instance.class.base_class.name}' and instance_id = #{@instance.id}) q
        WHERE performed = true
          AND lm.name IS NOT NULL
          AND (lm.instance_id != #{@instance.id} OR lm.instance_type != '#{@instance.class.base_class.name}')
          -- AND lm.instance_type = '#{@instance.class.base_class.name}'
        ORDER BY similarity_score DESC
        LIMIT 10
      SQL

      LexicalTransformation.find_by_sql(query)
    end
  end
end
