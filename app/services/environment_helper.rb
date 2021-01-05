module EnvironmentHelper
  def self.env
    if Rails.env.production? && ENV['STAGING'] == 'true'
      :staging
    else
      Rails.env.to_sym
    end
  end

  def self.development?; env == :development; end
  def self.test?;        env == :test;        end
  def self.staging?;     env == :staging;     end
  def self.production?;  env == :production;  end

  def self.is_host? host, request
    request.host_with_port == {
      :default => ENV['HOST'],
      :api => ENV['API_HOST'],
      :admin => ENV['ADMIN_HOST']
    }[host.to_sym]
  end

  def self.default_host? request; is_host? :default, request; end
  def self.api_host?     request; is_host? :api, request;     end
  def self.admin_host?   request; is_host? :admin, request;   end
end
