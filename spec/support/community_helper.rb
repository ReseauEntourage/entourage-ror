module CommunityHelper
  def with_community community
    community = Community.new(community)
    around do |example|
      default_community = $server_community
      $server_community = community
      example.run
      $server_community = default_community
    end
  end
end
