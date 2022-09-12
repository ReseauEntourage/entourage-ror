# frozen_string_literal: true

# This code is a sub-copy from https://github.com/rails/rails/blob/6-0-stable/activerecord/lib/active_record/store.rb
# Rails 5 provides this class but without magic methods (such as key_changed?) we need
# Please remove this class as soon as we migrate to Rails 6

require "active_support/core_ext/hash/indifferent_access"

module JsonStorable
  extend ActiveSupport::Concern

  module ClassMethods
    def store_accessor(store_attribute, *keys, prefix: nil, suffix: nil)
      keys = keys.flatten

      accessor_prefix =
        case prefix
        when String, Symbol
          "#{prefix}_"
        when TrueClass
          "#{store_attribute}_"
        else
          ""
        end
      accessor_suffix =
        case suffix
        when String, Symbol
          "_#{suffix}"
        when TrueClass
          "_#{store_attribute}"
        else
          ""
        end

      _store_accessors_module.module_eval do
        keys.each do |key|
          accessor_key = "#{accessor_prefix}#{key}#{accessor_suffix}"

          define_method("#{accessor_key}_changed?") do
            return false unless attribute_changed?(store_attribute)
            prev_store, new_store = changes[store_attribute]
            prev_store&.dig(key) != new_store&.dig(key)
          end

          define_method("#{accessor_key}_change") do
            return unless attribute_changed?(store_attribute)
            prev_store, new_store = changes[store_attribute]
            [prev_store&.dig(key), new_store&.dig(key)]
          end

          define_method("#{accessor_key}_was") do
            return unless attribute_changed?(store_attribute)
            prev_store, _new_store = changes[store_attribute]
            prev_store&.dig(key)
          end

          define_method("saved_change_to_#{accessor_key}?") do
            return false unless saved_change_to_attribute?(store_attribute)
            prev_store, new_store = saved_change_to_attribute(store_attribute)
            prev_store&.dig(key) != new_store&.dig(key)
          end

          define_method("saved_change_to_#{accessor_key}") do
            return unless saved_change_to_attribute?(store_attribute)
            prev_store, new_store = saved_change_to_attribute(store_attribute)
            [prev_store&.dig(key), new_store&.dig(key)]
          end

          define_method("#{accessor_key}_before_last_save") do
            return unless saved_change_to_attribute?(store_attribute)
            prev_store, _new_store = saved_change_to_attribute(store_attribute)
            prev_store&.dig(key)
          end
        end
      end
    end

    def _store_accessors_module # :nodoc:
      @_store_accessors_module ||= begin
        mod = Module.new
        include mod
        mod
      end
    end
  end
end
