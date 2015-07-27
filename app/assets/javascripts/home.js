var map;
var colors = {"other":"#FF0000", "social":"#00FF00", "food":"#0000FF"}
function initialize() {
  map = new google.maps.Map(document.getElementById('map-canvas'), {
    zoom: 13,
    center: new google.maps.LatLng(48.858859, 2.3470599),
  });

  map.data.setStyle(function(feature) {
    var tourType = feature.getProperty('tour_type');
    var color = colors[tourType];
    return ({
      strokeColor: color,
      strokeWeight: 2
    });
  });

  map.data.loadGeoJson('/latest_tours.json');
}

google.maps.event.addDomListener(window, 'load', initialize);
