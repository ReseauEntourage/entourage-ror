require 'pp'

class Community < BasicObject
  include ::Kernel
  include ::PP::ObjectMixin
  attr_reader :slug

  @@struct = {}

  def initialize community_slug
    @slug = community_slug.to_s
    load_from_file
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
    if ::Rails.env.development?
      load_from_file
    else
      @struct || from_global_memory || load_from_file
    end
  end

  def inspect
    "#<Community #{slug}>"
  end

  alias_method :to_s, :inspect
  alias_method :to_str, :slug

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

  private

  def from_global_memory
    @@struct[slug]
  end

  def load_from_file
    @file ||= ::File.expand_path("../communities/#{slug}.yml", __FILE__)
    @@struct[slug] = @struct = ::OpenStruct.new(::YAML.load_file(@file))
  rescue ::Errno::ENOENT
    raise "Community '#{slug}' is not defined"
  end
end
