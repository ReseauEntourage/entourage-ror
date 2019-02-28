module UserServices
  class UserRelationshipBuilder
    def initialize(source_user_id:, target_user_ids:, relation_type:)
      @source_user_id = source_user_id
      @target_user_ids = target_user_ids
      @relation_type = relation_type
      @callback = Callback.new
    end

    def create
      yield callback if block_given?

      target_user_ids.each do |target_user_id|
        UserRelationship.create!(source_user_id: source_user_id,
                                target_user_id: target_user_id,
                                relation_type: relation_type)
      end
      callback.on_success.try(:call)
    end

    private
    attr_reader :source_user_id, :target_user_ids, :relation_type, :callback
  end
end
