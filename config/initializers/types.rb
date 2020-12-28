# Custom Types
# https://github.com/rails/rails/blob/v5.0.7.2/activerecord/lib/active_record/attributes.rb#L114

require 'experimental/jsonb_set'
require 'experimental/jsonb_with_schema'

ActiveRecord::Type.register(:community, Community::Type)
ActiveRecord::Type.register(:jsonb_set, Experimental::JsonbSet)
ActiveRecord::Type.register(:jsonb_with_schema, Experimental::JsonbWithSchema)
