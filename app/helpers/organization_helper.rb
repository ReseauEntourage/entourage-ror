module OrganizationHelper
  def marker_index(index)
    return (index + 1).to_s if index < 9
    return ('A'.ord + index - 9).chr if index < 35
    return '?'
  end
end