$(document).on "page:change", ->
  map_rencontres_created = false

  $("#user-list a.send_sms").on("ajax:success", (e, data, status, xhr) ->
    alert 'Message envoyé'
  ).on "ajax:error", (e, xhr, status, error) ->
    alert "Erreur dans l'envoi du message"
    
  $("#send_message_form").on("ajax:success", (e, data, status, xhr) ->
    $('#flash').append('<p class="alert alert-success alert-dismissable"><button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button><span>' + xhr.responseText + '</span></p>')
    document.getElementById('send_message_form').reset()
    $('#messageModal').modal('hide')
  ).on "ajax:error", (e, xhr, status, error) ->
    alert "Erreur dans l'envoi du message"
    
  $('a[data-toggle="tab"]').on('shown.bs.tab', (e) ->
    if (!map_rencontres_created)
      map = new google.maps.Map(document.getElementById('map-rencontres'), {
        zoom: 13,
        center: new google.maps.LatLng(48.858859, 2.3470599),
      })
      
      refreshMap = () ->
        url = '/organization/encounters.json'
        tour_type_filter = document.getElementById('rencontres-tour-type-filter').value
        if (tour_type_filter != '')
          url += '?tour_type=' + tour_type_filter
        map.data.forEach((feature) ->
          map.data.remove(feature))
        map.data.loadGeoJson(url)
      
      $('.rencontres-map-filter').change(refreshMap)
      setInterval(refreshMap, 30 * 1000);
      
      refreshMap()
      
    map_rencontres_created = true
  )
  
    
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
    tour_type_filter = document.getElementById('maraudes-tour-type-filter').value
    if (tour_type_filter != '')
      url += '?tour_type=' + tour_type_filter
    map.data.forEach((feature) ->
      map.data.remove(feature))
    map.data.loadGeoJson(url)
  
  $('.maraudes-map-filter').change(refreshMap)
  setInterval(refreshMap, 30 * 1000);
  
  refreshMap()