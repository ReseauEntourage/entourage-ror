module Experimental
  def self.SymbolSet value
    Array(value).map { |v| v.try(:to_sym) }.compact.uniq.sort
  end
end
