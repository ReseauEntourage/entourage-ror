# Define New Relic app_name dynamically based on $COMMUNITY.
# examples: "PFP API", "Entourage API (Development)"
new_relic_app_name = "#{$server_community.dev_name} API"
if ENV['STAGING']
  new_relic_app_name += " (Staging)"
elsif !Rails.env.production?
  new_relic_app_name += " (#{Rails.env.capitalize})"
end

NewRelic::Control.instance.init_plugin(
  app_name: new_relic_app_name
)
