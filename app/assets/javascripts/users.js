var ready = function() {
  if ($(".users")[0]){
    $("#send_sms").click(function () {
      var user_id = $(this).data('user-id');
      var href = $(".modal-footer a").attr("href");
      $(".modal-footer a").attr("href", href.replace("%7Buser_id%7D", user_id));
    });
  }
};

$(document).ready(ready);
$(document).on('page:load', ready);