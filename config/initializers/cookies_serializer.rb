# Be sure to restart your server when you modify this file.

Rails.application.config.action_dispatch.cookies_serializer = :json
# @temporary remove as soon as Entourage version using Rails 5.2 is stable
# @see https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#expiry-in-signed-or-encrypted-cookie-is-now-embedded-in-the-cookies-values
Rails.application.config.action_dispatch.use_authenticated_cookie_encryption = false
