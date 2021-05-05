require 'experimental/symbol_set'

module Experimental
  class JsonbSet < ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Jsonb
    def deserialize(value)
      format(super(value))
    end

    def cast(value)
      super format(value)
    end

    def serialize(value)
      super format(value)
    end

    private

    def format value
      Experimental::SymbolSet(value).sort
    end
  end
end
