$(document).ready ->
  $("#user-list a.send_sms").on("ajax:success", (e, data, status, xhr) ->
    alert 'Message envoyé'
  ).on "ajax:error", (e, xhr, status, error) ->
    alert "Erreur dans l'envoi du message"
    
  map = new google.maps.Map(document.getElementById('map-maraudes'), {
    zoom: 13,
    center: new google.maps.LatLng(48.858859, 2.3470599),
  })
  
  map.data.setStyle((feature) ->
    tourType = feature.getProperty('tour_type')
    color = colors[tourType]
    {
      strokeColor: color,
      strokeWeight: 2
    }
  )
  
  refreshMap = () ->
    url = '/organization/tours.json'
    tour_type_filter = document.getElementById('tour-type-filter').value
    if (tour_type_filter != '')
      url += '?tour_type=' + tour_type_filter
    map.data.forEach((feature) ->
      map.data.remove(feature))
    map.data.loadGeoJson(url)
  
  $('.map-filter').change(refreshMap)
  
  refreshMap()