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

  def self.git_sha; ENV['HEROKU_SLUG_DESCRIPTION'] end
end
