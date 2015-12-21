function displayStatisticsMapData() {
  $.getJSON('/organizations/map_center', function (result) {

    var map_center = new google.maps.LatLng(result[0], result[1]);
    map = new google.maps.Map(document.getElementById('map-rencontres'), {
      zoom: 13,
      center: map_center
    });

    google.maps.event.addListenerOnce(map, 'idle', function(){
      var heatmap = new google.maps.visualization.HeatmapLayer({map: map});

      refreshMap = function() {
        var url = '/organizations/encounters.json';
        var filters = [];
        filters.push('ne=' + map.getBounds().getNorthEast().lat() + '-' + map.getBounds().getNorthEast().lng());
        filters.push('sw=' + map.getBounds().getSouthWest().lat() + '-' + map.getBounds().getSouthWest().lng());
        if ($('#rencontres-date-filter').val().length > 0) {
          filters.push('date_range=' + $('#rencontres-date-filter').val());
        }

        if ($('#rencontres-tour-type-filter').val() != null && $('#rencontres-tour-type-filter').val().length > 0) {
          filters.push('tour_type=' + $('#rencontres-tour-type-filter').val());
        }

        if ($('#rencontres-org-filter').val() != undefined && $('#rencontres-org-filter').val().length > 0) {
          filters.push('org=' + $('#rencontres-org-filter').val());
        }
        url += '?' + filters.join('&');
        heatmap.setMap(null);

        $.getJSON(url, function(data) {
          points = data.encounters.map(function(x) {return new google.maps.LatLng(x.latitude, x.longitude)} );
          heatmap = new google.maps.visualization.HeatmapLayer({
            data: points,
            radius: 40,
            map: map
          });

          $('#search-stats').html(HandlebarsTemplates['organization/stats'](data.stats));
        });
      };

      $('.rencontres-map-filter').change(refreshMap);
      map.addListener('idle', refreshMap);

      refreshMap();
    });
  });
}

var ready = function() {
  if ($(".organizations.statistics")[0]) {
    displayStatisticsMapData();
  }

  if ($(".organizations")[0]){
    $('[data-toggle="tooltip"]').tooltip();

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

    $('#rencontres-tour-type-filter').multiselect({ buttonClass :'btn btn-default multitest',
      nonSelectedText: 'Sélectionnez une option'});
  }
};

$(document).ready(ready);
$(document).on('page:load', ready);