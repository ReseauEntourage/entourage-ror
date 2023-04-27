# Allows to touch additional timestamps when saving/updating a record.
# See https://github.com/rails/rails/blob/v5.1.7/activerecord/lib/active_record/timestamp.rb
#
# Usage:
#
#   class MyModel < ApplicationRecord
#     include CustomTimestampAttributesForUpdate
#
#     before_save do
#       if some_condition
#         @custom_timestamp_attributes_for_update = ["some_timestamp_at"]
#       end
#     end
#  end
#
module CustomTimestampAttributesForUpdate
  extend ActiveSupport::Concern

  included do
    after_initialize { reset_timestamp_attributes_for_update }
    after_save :reset_timestamp_attributes_for_update
  end

  private

  def all_timestamp_attributes_in_model
    super + @custom_timestamp_attributes_for_update
  end

  def timestamp_attributes_for_update_in_model
    super + @custom_timestamp_attributes_for_update
  end

  def reset_timestamp_attributes_for_update
    @custom_timestamp_attributes_for_update = []
  end
end
