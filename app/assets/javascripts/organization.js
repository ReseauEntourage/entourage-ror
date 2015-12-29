function displayDashboardMapData() {
  $.getJSON('/organizations/map_center', function (result) {
    var map_center = new google.maps.LatLng(result[0], result[1]);

    map = new google.maps.Map(document.getElementById('map-maraudes'), {
      zoom: 13,
      center: map_center
    });

    var heatmap = new google.maps.visualization.HeatmapLayer({map: map});

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
        var tour_display_type = $("[name=tour_display_type]:checked").val();
        var url = '/organizations/tours.json';
        if($("#snapbox").val() == "true") {
          url = '/organizations/snap_tours.json';
        }
        else if($("#simplifiedbox").val() == "true") {
          url = '/organizations/simplified_tours.json';
        }
        var filters = [];
        filters.push('ne=' + map.getBounds().getNorthEast().lat() + '-' + map.getBounds().getNorthEast().lng());
        filters.push('sw=' + map.getBounds().getSouthWest().lat() + '-' + map.getBounds().getSouthWest().lng());
        if ($('#date-filter').val().length > 0) {
          filters.push('date_range=' + $('#date-filter').val());
        }

        if ($('#tour-type-filter').val() != null && $('#tour-type-filter').val().length > 0) {
          filters.push('tour_type=' + $('#tour-type-filter').val());
        }

        if ($('#org-filter').val() != undefined && $('#org-filter').val().length > 0) {
          filters.push('org=' + $('#org-filter').val());
        }

        if(tour_display_type=="heatmap") {
          filters.push('only_points=true');
        }

        url += '?' + filters.join('&');

        map.data.forEach(function(feature) {
          map.data.remove(feature);
        });
        heatmap.setMap(null);
        if(tour_display_type=="points") {
          map.data.loadGeoJson(url);
        }
        else {
          $.getJSON(url, function (data) {
            points = data.points.map(function (x) {
              return new google.maps.LatLng(x.latitude, x.longitude)
            });
            heatmap = new google.maps.visualization.HeatmapLayer({
              data: points,
              radius: 40,
              map: map
            });
          });
        }
      };

      $('.map-filter').change(refreshMap);
      map.addListener('idle', refreshMap);

      $("[name=tour_display_type]").change(function() {
        refreshMap();
      });

      refreshMap();

      $('#snapbox').change(function() {
        refreshMap();
      });
    });
  });
}

var ready = function() {
  if ($(".organizations.dashboard")[0]) {
    displayDashboardMapData();
  }

  $('input[name="pushdate"]').datepicker({dateFormat: 'dd/mm/yy', minDate: 0});
  $('#recipients-select').multiselect({ buttonClass :'btn btn-default multitest',
    nonSelectedText: 'Sélectionnez des destinataires'});

  $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
    var target = $(e.target).attr("href");
    if ((target == '#now')) {
      $('input[name="pushdate"]').datepicker();
    }else{
      $('input[name="pushdate"]').datepicker('setDate', new Date());
    }
  });



  
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
  });

  $('#tour-type-filter').multiselect({ buttonClass :'btn btn-default multitest',
                                                nonSelectedText: 'Sélectionnez une option'});
};




$(document).ready(ready);
$(document).on('page:load', ready);