module MixpanelTools
  class ResponseError < RuntimeError; end

  def self.request path, params={}
    puts "GET #{path} #{params.inspect}"
    response = HTTParty.get(
      File.join("https://mixpanel.com/api/2.0/", path.to_s),
      basic_auth: { username: ENV['MIXPANEL_SECRET'] },
      query: params
    )
    body = response.parsed_response
    if response.code.to_s[0] != '2' || body.has_key?('error')
      p body
      raise ResponseError, body['error']
    end
    body
  end

  def self.paginated_request path, params={}
    Enumerator.new do |y|
      pagination = {}
      page_size = nil

      loop do
        response = request path, pagination.merge(params)
        response['results'].each do |result|
          y << result
        end
        page_size = response['page_size'] || page_size
        break if response['results'].count < page_size
        pagination = {
          session_id: response['session_id'],
          page: response['page'] + 1
        }
      end
    end
  end

  def self.get_people params={}
    paginated_request('/engage/', params)
  end

  def self.batch_update updates
    updates.each_slice(50).map do |updates|
      updates.each do |update|
        update['$token'] = ENV['MIXPANEL_TOKEN']
        update['$ip'] ||= '0'
        update['$ignore_time'] = !update.has_key?('$time')
      end

      puts "POST /engage/ with #{updates.count} updates"
      HTTParty.post(
        "https://api.mixpanel.com/engage/",
        body: { data: Base64.strict_encode64(JSON.fast_generate(updates)) }
      ).parsed_response
    end
  end
end
