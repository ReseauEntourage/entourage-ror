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

  def admin_roles
    memoize(:admin_roles) { ::Experimental::SymbolSet(struct.admin_roles) }
  end

  def targeting_profiles
    memoize(:targeting_profiles) { ::Experimental::SymbolSet(struct.targeting_profiles) }
  end

  def goals
    memoize(:goals) { ::Experimental::SymbolSet(struct.goals) }
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

  def as_json t
    slug
  end

  def inspect
    "#<Community #{slug}>"
  end

  alias_method :to_s, :inspect
  alias_method :to_str, :slug # implicit comparison with strings

  # https://github.com/rails/rails/blob/v5.0.7.2/activerecord/lib/active_record/sanitization.rb#L226
  def quoted_id
    ::ActiveRecord::Base.connection.quote Type.new.serialize(slug)
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

  class Type < ::ActiveModel::Type::String
    # https://github.com/rails/rails/blob/v5.0.7.2/activerecord/lib/active_record/attributes.rb
    # https://github.com/rails/rails/blob/v5.0.7.2/activemodel/lib/active_model/type/value.rb
    # https://github.com/rails/rails/blob/v5.0.7.2/activemodel/lib/active_model/type/string.rb

    def deserialize(value)
      return value if value.blank?
      Community.new(value)
    rescue Community::NotFound
      nil
    end

    def cast(value)
      return nil if value.nil?
      Community.new(value)
    end

    def serialize(value)
      Community.slug(value)
    end
  end
end
