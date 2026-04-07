module SmalltalkHelper
  def chart_data smalltalk_id, chart_data
    data = {}
    
    7.times do |i|
      date = i.days.ago.to_date
      date_key = date.strftime('%Y-%m-%d')
      label = date.strftime('%d/%m')
      data[label] = chart_data[[smalltalk_id, date_key]] || 0
    end
    
    data.to_a.reverse.to_h
  end
end
