class Community < BasicObject
  include ::Kernel
  include ::PP::ObjectMixin if defined?(::PP)
  attr_reader :community

  def initialize community
    @community = community
    @file = ::File.expand_path("../communities/#{community}.yml", __FILE__)
    load!
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
      load!
    else
      @struct || load!
    end
  end

  def load!
    @struct = ::OpenStruct.new(::YAML.load_file(@file))
  rescue ::Errno::ENOENT
    raise "Community '#{community}' is not defined"
  end

  def inspect
    "#<Community #{community}>"
  end

  def == other
    case other
    when ::String, ::Symbol
      community == other.to_s
    when ::Community
      community == other.community
    else
      raise ::ArgumentError, "comparison of Community with #{other.class.name} failed"
    end
  end
end

raise "Environment variable COMMUNITY must be set" if ENV['COMMUNITY'].blank?
$community = Community.new ENV['COMMUNITY']
