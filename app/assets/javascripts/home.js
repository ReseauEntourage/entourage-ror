var map;
function initialize() {
  // Create a simple map.
  map = new google.maps.Map(document.getElementById('map-canvas'), {
    zoom: 13,
    center: new google.maps.LatLng(48.858859, 2.3470599),
    mapTypeId: google.maps.MapTypeId.TERRAIN
  });

  // Load a GeoJSON from the same server as our demo.
  map.data.loadGeoJson('http://entourage-back-preprod.herokuapp.com/latest_tours.json');
}

google.maps.event.addDomListener(window, 'load', initialize);
