# frozen_string_literal: true

# Make `average` work in ruby 2.6+
# https://github.com/rails/rails/pull/34858
raise if Rails.version >= '5'

module ActiveRecord
  module Calculations
    private

    alias_method :_type_cast_calculated_value, :type_cast_calculated_value

    def type_cast_calculated_value(value, type, operation = nil)
      if operation == 'average'
        value&.respond_to?(:to_d) ? value.to_d : value
      else
        _type_cast_calculated_value(value, type, operation)
      end
    end
  end
end
