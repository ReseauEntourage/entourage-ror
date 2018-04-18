require 'pp'

class Community < BasicObject
  include ::Kernel
  include ::PP::ObjectMixin
  attr_reader :community

  @@struct = {}

  def initialize community
    @community = community.to_s
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
    "#<Community #{community}>"
  end

  alias_method :to_s, :inspect

  def == other
    case other
    when ::String, ::Symbol
      community == other.to_s
    when ::Community
      community == other.community
    when ::NilClass
      false
    else
      raise ::ArgumentError, "comparison of Community with #{other.class.name} failed"
    end
  end

  private

  def from_global_memory
    @@struct[community]
  end

  def load_from_file
    @file ||= ::File.expand_path("../communities/#{community}.yml", __FILE__)
    @@struct[community] = @struct = ::OpenStruct.new(::YAML.load_file(@file))
  rescue ::Errno::ENOENT
    raise "Community '#{community}' is not defined"
  end
end
