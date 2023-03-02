in_path = ARGV[0]
out_path = ARGV[1]

if in_path.nil? || out_path.nil?
  $stderr.puts "Usage: #{$SCRIPT_NAME} <file-1.csv> <file-2.csv>"
  exit 1
end

def clean_file in_path, out_path
  columns = [:donator_sex, :donator_country, :donator_postcode, :donator_city, :payment_frequency, :campaign_type, :context_query_string, :context_referer, :donation_amount, :donation_category, :donation_next_transaction_date, :donation_reference, :donation_status, :donation_type, :donation_validation_date, :donator_email, :payment_card_renew_key, :payment_gateway_account, :payment_gateway_ticket_EMAIL, :payment_gateway_ticket_metadata_donator_email, :payment_gateway_ticket_RECEIVERBUSINESS, :payment_gateway_ticket_RECEIVEREMAIL, :payment_succeeded, :sympathizer_id]

  csv_table = CSV.read(in_path, col_sep: ';', quote_char: nil, headers: true, header_converters: :symbol, encoding: 'iso-8859-1:utf-8')
  (csv_table.headers - columns).each do |column|
    csv_table.delete(column)
  end

  CSV.open(out_path, 'w+', force_quotes: false, col_sep: ';') do |csv|
    csv << csv_table.headers
    csv_table.each_with_index do |row|
      csv << row
    end
  end
end

clean_file(in_path, out_path) { |csv| process_csv csv }
