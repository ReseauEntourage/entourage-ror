function initialize() {
  var mapOptions = {
    zoom: 13,
    center: new google.maps.LatLng(48.858859, 2.3470599),
    mapTypeId: google.maps.MapTypeId.TERRAIN
  };

  var map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions);
  var flightPlanCoordinates = []

  $(document).ready(function() {
    $.ajax({
        url: "http://entourage-back-preprod.herokuapp.com/tours/24.json?token=TOKEN"
    }).then(function(data) {



      for (i = 0; i < data.tour.tour_points.length; i++) {
        tour_point = data.tour.tour_points[i];
        flightPlanCoordinates.push(new google.maps.LatLng(tour_point.latitude, tour_point.longitude))
      }
      var flightPath = new google.maps.Polyline({
        path: flightPlanCoordinates,
        geodesic: true,
        strokeColor: '#FF0000',
        strokeOpacity: 1.0,
        strokeWeight: 2
      });
      flightPath.setMap(map);


    });
  });
}

google.maps.event.addDomListener(window, 'load', initialize);
