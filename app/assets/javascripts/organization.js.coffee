$(document).ready ->
  $("#user-list a.send_sms").on("ajax:success", (e, data, status, xhr) ->
    alert 'Message envoyé'
  ).on "ajax:error", (e, xhr, status, error) ->
    alert "Erreur dans l'envoi du message"
    
  map = new google.maps.Map(document.getElementById('map-maraudes'), {
    zoom: 13,
    center: new google.maps.LatLng(48.858859, 2.3470599),
  });
  