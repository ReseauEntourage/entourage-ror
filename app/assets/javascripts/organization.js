function displayDashboardMapData() {
  $.getJSON('/organizations/map_center', function (result) {
    var map_center = new google.maps.LatLng(result[0], result[1]);

    map = new google.maps.Map(document.getElementById('map-maraudes'), {
      zoom: 13,
      center: map_center
    });

    colors = {"health": "red", "friendly": "magenta", "social": "green", "food": "blue", "other": "black"};

    map.data.setStyle(function (feature) {
      tourType = feature.getProperty('tour_type');
      color = colors[tourType];
      return {
        strokeColor: color,
        strokeWeight: 2
      }
    });

    google.maps.event.addListenerOnce(map, 'idle', function(){
      refreshMap = function() {
        var url = '/organizations/tours.json';
        var filters = [];
        filters.push('ne=' + map.getBounds().getNorthEast().lat() + '-' + map.getBounds().getNorthEast().lng());
        filters.push('sw=' + map.getBounds().getSouthWest().lat() + '-' + map.getBounds().getSouthWest().lng());
        if ($('#maraudes-date-filter').val().length > 0) {
          filters.push('date_range=' + $('#maraudes-date-filter').val());
        }

        if ($('#maraudes-tour-type-filter').val().length > 0) {
          filters.push('tour_type=' + $('#maraudes-tour-type-filter').val());
        }

        if ($('#maraudes-org-filter').val() != undefined && $('#maraudes-org-filter').val().length > 0) {
          filters.push('org=' + $('#maraudes-org-filter').val());
        }
        url += '?' + filters.join('&');
        map.data.forEach(function(feature) {
          map.data.remove(feature);
        });
        map.data.loadGeoJson(url);
      };

      $('.maraudes-map-filter').change(refreshMap);
      map.addListener('idle', refreshMap);

      refreshMap();
    });
  });
}

var ready = function() {
  if ($(".organizations.dashboard")[0]) {
    displayDashboardMapData();
  }
};

$(document).ready(ready);
$(document).on('page:load', ready);