$(document).on "page:change", ->
  map_rencontres_created = false

  $('[data-toggle="tooltip"]').tooltip()

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
  
  $('input[name="daterange"]').daterangepicker({
    opens:'left',
    linkedCalendars: false,
    ranges: {
      "Aujourd'hui": [moment(), moment()],
      "Hier": [moment().subtract(1, 'days'), moment().subtract(1, 'days')],
      "Les 7 derniers jours": [moment().subtract(6, 'days'), moment()],
      "Les 30 derniers jours": [moment().subtract(29, 'days'), moment()],
      "Le mois en cours": [moment().startOf('month'), moment().endOf('month')],
      "Le mois dernier": [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')]
    },
    locale: {
      "format": "DD/MM/YYYY",
      "separator": "-",
      "applyLabel": "OK",
      "cancelLabel": "Annuler",
      "fromLabel": "De",
      "toLabel": "à",
      "customRangeLabel": "Autre",
      "daysOfWeek": [
        "Dim",
        "Lun",
        "Mar",
        "Mer",
        "Jeu",
        "Ven",
        "Sam"
      ],
      "monthNames": [
        "Janvier",
        "Février",
        "Mars",
        "Avril",
        "Mai",
        "Juin",
        "Juillet",
        "Aout",
        "Septembre",
        "Octobre",
        "Novembre",
        "Decembre"
      ],
      "firstDay": 1
    }
  })
  
  $('a[data-toggle="tab"]').on('shown.bs.tab', (e) ->
    if (!map_rencontres_created)
      map = new google.maps.Map(document.getElementById('map-rencontres'), {
        zoom: 13,
        center: new google.maps.LatLng(48.858859, 2.3470599),
      })
      heatmap = new google.maps.visualization.HeatmapLayer({map: map})
      
      refreshMap = () ->
        url = '/organization/encounters.json'
        filters = []
        filters.push('ne=' + map.getBounds().getNorthEast().lat() + '-' + map.getBounds().getNorthEast().lng())
        filters.push('sw=' + map.getBounds().getSouthWest().lat() + '-' + map.getBounds().getSouthWest().lng())
        if (document.getElementById('rencontres-date-filter').value.length > 0)
          filters.push('date_range=' + document.getElementById('rencontres-date-filter').value)
        if (document.getElementById('rencontres-tour-type-filter').value.length > 0)
          filters.push('tour_type=' + document.getElementById('rencontres-tour-type-filter').value)
        if (document.getElementById('rencontres-org-filter') != null && document.getElementById('rencontres-org-filter').value.length > 0)
          filters.push('org=' + document.getElementById('rencontres-org-filter').value)
        url += '?' + filters.join('&')
        heatmap.setMap(null)
        $.getJSON(url, (data) ->
          points = data.encounters.map((x) -> new google.maps.LatLng(x.latitude, x.longitude))
          heatmap = new google.maps.visualization.HeatmapLayer({
            data: points,
            radius: 40,
            map: map
          })
          $('#search-stats').html(HandlebarsTemplates['organization/stats'](data.stats))
        )
      
      $('.rencontres-map-filter').change(refreshMap)
      map.addListener('idle', refreshMap)
      setInterval(refreshMap, 30 * 1000);
      
      refreshMap()
      
    map_rencontres_created = true
  )
  
    
  map = new google.maps.Map(document.getElementById('map-maraudes'), {
    zoom: 13,
    center: new google.maps.LatLng(48.858859, 2.3470599),
  })
  
  colors = { "health":"red", "friendly":"magenta", "social":"green", "food":"blue", "other":"black" }
  
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
    filters = []
    if (document.getElementById('maraudes-date-filter').value.length > 0)
      filters.push('date_range=' + document.getElementById('maraudes-date-filter').value)
    if (document.getElementById('maraudes-tour-type-filter').value.length > 0)
      filters.push('tour_type=' + document.getElementById('maraudes-tour-type-filter').value)
    if (document.getElementById('maraudes-org-filter') != null && document.getElementById('maraudes-org-filter').value.length > 0)
      filters.push('org=' + document.getElementById('maraudes-org-filter').value)
    url += '?' + filters.join('&')
    map.data.forEach((feature) ->
      map.data.remove(feature))
    map.data.loadGeoJson(url)
  
  $('.maraudes-map-filter').change(refreshMap)
  setInterval(refreshMap, 30 * 1000);
  
  refreshMap()