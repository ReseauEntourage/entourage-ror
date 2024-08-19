# this module handles contributions and solicitations matchings using bert vectors
module Bertable
  extend ActiveSupport::Concern

  included do
    after_create :bert_on_create

    has_one :lexical_transformation, as: :instance
  end

  BertStruct = Struct.new(:instance) do
    def initialize(instance: nil)
      @instance = instance
    end

    def on_create
      lexical_transformation = @instance.lexical_transformation || @instance.build_lexical_transformation

      fields.each do |instance_field, relation_field|
        next unless @instance.has_attribute?(instance_field)
        next unless lexical_transformation.has_attribute?(relation_field)

        lexical_transformation[relation_field] = @instance[instance_field]
      end

      lexical_transformation.save!
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

    private

    def fields
      return { title: :name, description: :description } if @instance.is_a?(Entourage) && @instance.action?
      return { name: :name, description: :description } if @instance.is_a?(Neighborhood)
      return { name: :name, description: :description } if @instance.is_a?(Resource)

      {}
    end

    def relation
      @relation ||= LexicalTransformation.find_or_initialize_by(instance_type: @instance.class.base_class.name, instance_id: @instance.id)
    end
  end

  def bert
    @bert ||= BertStruct.new(instance: self)
  end

  def bert_on_create
    bert.on_create
  end
end
