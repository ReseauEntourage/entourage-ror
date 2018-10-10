module Typeform
  class ResponseError < RuntimeError; end

  def self.request form_id, params={}
    puts "GET /forms/#{form_id}/responses #{params.inspect}"
    response = HTTParty.get(
      "https://api.typeform.com/forms/#{form_id}/responses",
      headers: {authorization: "bearer #{ENV['TYPEFORM_TOKEN']}"},
      query: params
    )

    begin
      body = JSON.parse(response.body)
    rescue
      puts response.body
      raise ResponseError, response.body
    end

    if response.code.to_s[0] != '2'
      p body
      raise ResponseError, body['description']
    end
    body
  end

  def self.redis_key form_id
    "typeform_sync:#{form_id}:last_token"
  end

  def self.paginated_request form_id, params={}
    pagination = {
      sort: 'submitted_at,asc',
      page_size: 100, # 1000 max
      after: $redis.get(redis_key(form_id))
    }

    Enumerator.new do |y|
      loop do
        response = request form_id, pagination.merge(params)
        response['items'].each do |item|
          y << item
        end
        if response['items'].count < pagination[:page_size]
          $redis.set(redis_key(form_id), pagination[:after])
          break
        end
        pagination[:after] = response['items'].last['token']
      end
    end
  end

  def self.get_responses form_id
    paginated_request form_id, completed: true
  end

  def self.answers response
    answers = {}

    response['answers'].map do |answer|
      type = answer['type']
      value =
        case type
        when 'choice'
          answer[type]['label']
        when 'choices'
          answer[type]['labels']
        else
          answer[type]
        end

      answers[answer['field']['id']] = value
    end if response['answers'].present?

    answers.merge!(response['hidden']) if response['hidden'].present?

    answers
  end
end
