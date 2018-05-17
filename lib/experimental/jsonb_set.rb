require 'experimental/symbol_set'

module Experimental
  class JsonbSet < ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Jsonb
    def type_cast_from_database(value)
      format(super(value))
    end

    def type_cast_from_user(value)
      super format(value)
    end

    def type_cast_for_database(value)
      super format(value)
    end

    private

    def format value
      Experimental::SymbolSet(value)
    end
  end
end
