var apiKey = 'AIzaSyDphfsFA2hSW8mBKEq3Mt-6bq4dzVLd_80';

var map;
var drawingManager;
var placeIdArray = [];
var polylines = [];
var snappedCoordinates = [];

function initialize() {
  if($(".generate_tours")[0]) {
    var mapOptions = {
      zoom: 12,
      center: {lat: 48.873002, lng: 2.316136}
    };
    map = new google.maps.Map(document.getElementById('map'), mapOptions);

    // Adds a Places search box. Searching for a place will center the map on that
    // location.
    map.controls[google.maps.ControlPosition.RIGHT_TOP].push(
        document.getElementById('bar'));
    var autocomplete = new google.maps.places.Autocomplete(
        document.getElementById('autoc'));
    autocomplete.bindTo('bounds', map);
    autocomplete.addListener('place_changed', function() {
      var place = autocomplete.getPlace();
      if (place.geometry.viewport) {
        map.fitBounds(place.geometry.viewport);
      } else {
        map.setCenter(place.geometry.location);
        map.setZoom(17);
      }
    });

    // Enables the polyline drawing control. Click on the map to start drawing a
    // polyline. Each click will add a new vertice. Double-click to stop drawing.
    drawingManager = new google.maps.drawing.DrawingManager({
      drawingMode: google.maps.drawing.OverlayType.POLYLINE,
      drawingControl: true,
      drawingControlOptions: {
        position: google.maps.ControlPosition.TOP_CENTER,
        drawingModes: [
          google.maps.drawing.OverlayType.POLYLINE
        ]
      },
      polylineOptions: {
        strokeColor: '#696969',
        strokeWeight: 2
      }
    });
    drawingManager.setMap(map);

    // Snap-to-road when the polyline is completed.
    drawingManager.addListener('polylinecomplete', function(poly) {
      var path = poly.getPath();
      polylines.push(poly);
      placeIdArray = [];
      runSnapToRoad(path);
    });

    // Clear button. Click to remove all polylines.
    $('#clear').click(function(ev) {
      for (var i = 0; i < polylines.length; ++i) {
        polylines[i].setMap(null);
      }
      polylines = [];
      ev.preventDefault();
      return false;
    });
  }

  // Snap a user-created polyline to roads and draw the snapped path
  function runSnapToRoad(path) {
    var pathValues = [];
    for (var i = 0; i < path.getLength(); i++) {
      pathValues.push(path.getAt(i).toUrlValue());
    }

    $.get('https://roads.googleapis.com/v1/snapToRoads', {
      interpolate: true,
      key: apiKey,
      path: pathValues.join('|')
    }, function(data) {
      processSnapToRoadResponse(data);
      drawSnappedPolyline();
    });
  }

  // Store snapped polyline returned by the snap-to-road method.
  function processSnapToRoadResponse(data) {
    snappedCoordinates = [];
    placeIdArray = [];
    for (var i = 0; i < data.snappedPoints.length; i++) {
      var latlng = new google.maps.LatLng(
          data.snappedPoints[i].location.latitude,
          data.snappedPoints[i].location.longitude);
      snappedCoordinates.push(latlng);
      placeIdArray.push(data.snappedPoints[i].placeId);
    }
  }

  // Draws the snapped polyline (after processing snap-to-road response).
  function drawSnappedPolyline() {
    var snappedPolyline = new google.maps.Polyline({
      path: snappedCoordinates,
      strokeColor: 'black',
      strokeWeight: 3
    });

    snappedPolyline.setMap(map);
    polylines.push(snappedPolyline);

    $.ajax({
      type: "POST",
      url: "/admin/generate_tours",
      data: JSON.stringify({coordinates: snappedCoordinates}),
      contentType: "application/json; charset=utf-8",
      dataType: "json",
      success: function (data) {
        console.log("Tour was created");
      },
      failure: function (errMsg) {
        console.log("could not create tour : " + errMsg);
      }
    });
  }
}


$(window).load(initialize);