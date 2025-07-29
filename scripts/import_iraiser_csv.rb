path = ARGV[0]

if path.nil?
  $stderr.puts "Usage: #{$SCRIPT_NAME} <file.csv>"
  exit 1
end

def open_path path
  file = File.open(path, 'rb')
  csv = CSV.open(file, col_sep: ';', quote_char: nil, headers: true, header_converters: :symbol)
  yield csv
ensure
  file.close
  csv.close
end

def process_csv csv
  regular_setups = extract_regular_setups csv
  csv.rewind

  first_donations = extract_first_donations csv
  csv.rewind

  csv.each { |row| process_row row, regular_setups, first_donations }
end

def extract_regular_setups csv
  regular_setups = {}
  csv.each do |row|
    next if row[:payment_gateway_account].in? %w[iraisertest test]
    next unless row[:payment_succeeded] == '1'
    next unless row[:donation_type] == 'setup'

    regular_setups[row[:donation_reference]] = row
  end

  regular_setups
end

def extract_first_donations csv
  first_donations = {}
  csv.each do |row|
    next if row[:payment_gateway_account].in? %w[iraisertest test]
    next unless (row[:payment_succeeded] == '1' ||
                 (row[:donation_category] == 'pledge' &&
                  row[:donation_status] == 'validated'))
    next unless row[:donation_type].in? %w[once regular]

    if first_donations[row[:sympathizer_id]].nil? ||
       first_donations[row[:sympathizer_id]] > row[:donation_validation_date]
      first_donations[row[:sympathizer_id]] = row[:donation_validation_date]
    end
  end
  first_donations
end

def process_row row, regular_setups, first_donations
  return if row[:payment_gateway_account].in? %w[iraisertest test]
  return unless (row[:payment_succeeded] == '1' ||
                 (row[:donation_category] == 'pledge' &&
                  row[:donation_status] == 'validated'))
  return unless row[:donation_type].in? %w[once regular]

  donation_type =
    if row[:donation_type] == 'once'
      'once'
    elsif row[:campaign_type] != 'upgrade' &&
          row[:donation_next_transaction_date].nil?
      'first_regular'
    else
      'regular'
    end

  source = nil
  medium = nil
  host = nil

  if row[:context_referer]
    row[:context_referer].split(' -> ').each do |url|
      url = URI(url)
      query = CGI.parse(url.query || '')
      source = query['utm_source']&.first if source.nil?
      medium = query['utm_medium']&.first if medium.nil?
      host = url.host if host.nil?
    end
  end

  if row[:context_query_string]
    begin
      params = JSON.parse(row[:context_query_string])
    rescue
      params = CGI.parse(row[:context_query_string])
    end
    source = Array(params['utm_source']).first if source.nil?
    medium = Array(params['utm_medium']).first if medium.nil?
  end

  channel = source.nil? ? host : "#{source}/#{medium || '(none)'}"

  first_donation = row[:donation_validation_date] == first_donations[row[:sympathizer_id]]

  emails = extract_emails row
  app_user_id = User
    .where(community: :entourage)
    .where('lower(email) in (?)', emails)
    .order('last_sign_in_at desc nulls last, created_at desc')
    .limit(1)
    .pluck(:id)
    .first

  d = Donation.find_or_initialize_by(reference: row[:donation_reference])
  d.assign_attributes(
    date: Time.zone.parse(row[:donation_validation_date]).to_date,
    amount: (row[:donation_amount].to_i / 100.0).round,
    donation_type: donation_type,
    channel: channel,
    sex: row[:donator_sex],
    country: row[:donator_country],
    postal_code: row[:donator_postcode],
    city: row[:donator_city],
    payment_frequency: row[:payment_frequency],
    donator_birthdate: row[:sympathizer_birthdate],
    payment_type: row[:payment_type],
    iraiser_donator_id: row[:sympathizer_id],
    donator_iraiser_account_creation_date: row[:sympathizer_optin_date],
    donation_once_last_date: row[:sympathizer_donation_once_last_date],
    donation_regular_first_date: row[:sympathizer_donation_regular_first_date],
    donator_donation_regular_amount: row[:sympathizer_donation_regular_amount],
    donator_donation_regular_last_year_total: row[:sympathizer_donation_regular_last_year_total],
    donator_donation_regular_last_date: row[:sympathizer_donation_regular_last_date],
    first_time_donator: first_donation,
    app_user_id: app_user_id
  )
  if d.save == false
    puts "#{d.reference}: #{d.error.full_messages.to_sentence}"
  end
end

def extract_emails row
  candidates = []

  candidates << row[:donator_email]
  candidates << row[:payment_gateway_ticket_metadata_donator_email]
  candidates << row[:payment_gateway_ticket_RECEIVERBUSINESS]
  candidates << row[:payment_gateway_ticket_RECEIVEREMAIL]
  candidates << row[:payment_gateway_ticket_EMAIL]

  if row[:context_referer]
    row[:context_referer].split(' -> ').each do |url|
      params = CGI.parse(URI(url).query || '')
      candidates += params.values.flatten.uniq
    end
  end

  if row[:context_query_string]
    begin
      params = JSON.parse(row[:context_query_string])
    rescue
      params = CGI.parse(row[:context_query_string])
    end
    candidates += params.values.flatten.uniq
  end

  candidates = candidates
    .compact
    .map do |c|
      begin
        c.gsub(/\s+/, '').downcase.presence
      rescue => e
        nil
      end
    end.compact.uniq
    .select { |c| c.match?(/\A[^@]+@[^@]+\.[^@]+\z/) }
end

open_path(path) { |csv| process_csv csv }
