class FacebookAuthenticationProvider < AuthenticationProvider
  default_scope { where(provider: "facebook") }

  def avatar_url
    "https://graph.facebook.com/#{self.provider_id}/picture?type=large"
  end
end