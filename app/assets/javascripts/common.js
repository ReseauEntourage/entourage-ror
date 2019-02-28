var ready = function() {
  $(".tooltip-infos").tooltip();
}

$(document).ready(ready);
$(document).on('page:load', ready);
