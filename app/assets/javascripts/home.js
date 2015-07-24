// function initialize() {

//   var mapOptions = {
//     zoom: 13,
//     center: new google.maps.LatLng(48.858859, 2.3470599),
//     mapTypeId: google.maps.MapTypeId.TERRAIN
//   };

//   var map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions);
//   var colors = [
//     "#FF0000", 
//     "#00FF00", 
//     "#0000FF", 
//     "#FFFF00", 
//     "#00FFFF", 
//     "#FF00FF"
//   ];  
  
//   $(document).ready(function() {
//     $.ajax({
//         url: "http://entourage-back-preprod.herokuapp.com/"
//     }).then(function(data) {
//       var tourCoordinates = [];
//       for (i = 0; i < data.tours.length; i++) {
//         tour = data.tours[i];
//         for (j = 0; j < tour.tour_points.length; j++) {
//           tourPoint = tour.tour_points[j];
//           tourCoordinates.push(new google.maps.LatLng(tourPoint.latitude, tourPoint.longitude))
//         }
//         console.log("drawing new Polyline with color " + colors[i%8]);
//         var tourPath = new google.maps.Polyline({
//           path: tourCoordinates,
//           geodesic: true,
//           strokeColor: colors[i%6],
//           strokeOpacity: 1.0,
//           strokeWeight: 2,
//         });
//         tourPath.setMap(map);
//       }
//     });
//   });
// }

// google.maps.event.addDomListener(window, 'load', initialize);


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