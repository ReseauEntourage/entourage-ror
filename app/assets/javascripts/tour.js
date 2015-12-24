function displayDashboardMapData(tour_id) {
  $.getJSON('/tour/'+tour_id+'/map_center', function (result) {
    var map_center = new google.maps.LatLng(result[0], result[1]);

    map = new google.maps.Map(document.getElementById('map-maraudes'), {
      zoom: 13,
      center: map_center
    });

    var url = '/tours/'+tour_id+'/map_data.json';
    //to remove ?
    map.data.forEach(function(feature) {
      map.data.remove(feature);
    });
    map.data.loadGeoJson(url);
  });
}

var ready = function() {
  if ($(".tour")[0]) {
    var tour_id = window.location.href.split().slice(-1).pop();
    displayDashboardMapData(tour_id);
  }
};

$(document).ready(ready);
$(document).on('page:load', ready);