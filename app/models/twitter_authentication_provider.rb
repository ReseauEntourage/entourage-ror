class TwitterAuthenticationProvider < AuthenticationProvider
  default_scope { where(provider: "twitter") }
end
