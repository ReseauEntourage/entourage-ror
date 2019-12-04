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
  csv.each { |row| process_row row }
end

def process_row row
  return unless row[:payment_succeeded] == '1'
  return unless row[:donation_type].in? %w[once regular]
  return if row[:payment_gateway_account].in? %w[iraisertest test]

  raise unless row[:donation_type].in? %[once regular]

  donation_type =
    if row[:donation_type] == 'once'
      'once'
    elsif row[:donation_next_transaction_date].nil?
      'first_regular'
    else
      'regular'
    end

  source = nil
  medium = nil
  host = nil
  if row[:context_referer]
    row[:context_referer].split(" -> ").each do |url|
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
    source = params['utm_source']&.first if source.nil?
    medium = params['utm_medium']&.first if medium.nil?
  end
  channel = source.nil? ? host : "#{source}/#{medium || '(none)'}"

  d = Donation.find_or_initialize_by(reference: row[:donation_reference])
  d.assign_attributes(
    date: Time.zone.parse(row[:donation_validation_date]).to_date,
    amount: (row[:donation_amount].to_i / 100.0).round,
    donation_type: donation_type,
    channel: channel
  )
  if d.save == false
    puts "#{d.reference}: #{d.error.full_messages.to_sentence}"
  end
end

open_path(path) { |csv| process_csv csv }
