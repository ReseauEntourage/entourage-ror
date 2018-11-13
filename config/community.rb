require 'pp'
require_relative '../lib/experimental/memoize'
require_relative '../lib/experimental/symbol_set'

class Community < BasicObject
  include ::Kernel
  include ::PP::ObjectMixin
  include ::Experimental::Memoize
  attr_reader :slug

  @@struct = {}

  def initialize slug
    @slug = ::Community.slug(slug)

    # load immediately to detect if name is invalid
    struct
  end

  def users
    ::User.where(community: slug)
  end

  def entourages
    ::Entourage.where(community: slug)
  end

  def feeds
    ::Feed.where(community: slug)
  end

  def memoize?
    ::Rails.env.development? == false
  end

  def roles
    memoize(:roles) { ::Experimental::SymbolSet(struct.roles) }
  end

  def group_types
    struct.group_types || []
  end

  def method_missing name, *args
    super if args.any?
    return self == $1 if name =~ /^(.*)\?$/
    value = struct.send name
    if value != nil
      value
    else
      super
    end
  end

  def struct
    if memoize?
      @struct || from_global_memory || load_from_file
    else
      load_from_file
    end
  end

  def inspect
    "#<Community #{slug}>"
  end

  alias_method :to_s, :inspect
  alias_method :to_str, :slug # implicit comparison with strings

  # https://github.com/rails/rails/blob/v4.2.10/activerecord/lib/active_record/sanitization.rb#L187
  def quoted_id
    ::ActiveRecord::Base.connection.quote Type.new.type_cast_for_database(slug)
  end

  def == other
    ::Community.slug(other) == slug
  rescue ::ArgumentError
    false
  end

  def self.slug object
    case object
    when ::Community
      object.slug
    when ::String
      object
    when ::Symbol
      object.to_s
    when ::NilClass
      nil
    else
      raise ::ArgumentError, "conversion to Community slug of #{object.class.name} failed"
    end
  end

  def self.slugs
    @list ||= ::Dir[::File.expand_path("../communities/*.yml", __FILE__)].map do |path|
      ::File.basename(path, '.yml')
    end
  end

  class NotFound < ::RuntimeError; end

  private

  def from_global_memory
    @@struct[slug]
  end

  def load_from_file
    @file ||= ::File.expand_path("../communities/#{slug}.yml", __FILE__)
    @@struct[slug] = @struct = ::OpenStruct.new(::YAML.load_file(@file))
  rescue ::Errno::ENOENT
    raise NotFound, "Community #{slug.inspect} is not defined"
  end

  class Type < ::ActiveRecord::Type::String
    # https://github.com/rails/rails/blob/v4.2.10/activerecord/lib/active_record/attributes.rb
    # https://github.com/rails/rails/blob/v4.2.10/activerecord/lib/active_record/type/value.rb
    # https://github.com/rails/rails/blob/v4.2.10/activerecord/lib/active_record/type/string.rb

    def type_cast_from_database(value)
      return value if value.blank?
      Community.new(value)
    rescue Community::NotFound
      nil
    end

    def type_cast_from_user(value)
      return nil if value.nil?
      Community.new(value)
    end

    def type_cast_for_database(value)
      Community.slug(value)
    end
  end
end
