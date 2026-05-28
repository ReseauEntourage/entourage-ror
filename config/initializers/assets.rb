# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Serve app/javascript/ files via Sprockets (required by importmap-rails for local pins)
Rails.application.config.assets.paths << Rails.root.join("app/javascript")
