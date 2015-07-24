var map;

function initialize() {
  map = new google.maps.Map(document.getElementById('map-canvas'), {
    zoom: 13,
    center: new google.maps.LatLng(48.858859, 2.3470599),
    mapTypeId: google.maps.MapTypeId.TERRAIN
  });

  map.data.setStyle(function(feature) {
    var color = 'red';
    return /** @type {google.maps.Data.StyleOptions} */({
      strokeColor: "#FF0000",
      strokeWeight: 2
    });
  });

  map.data.loadGeoJson('/latest_tours.json');
}

google.maps.event.addDomListener(window, 'load', initialize);
