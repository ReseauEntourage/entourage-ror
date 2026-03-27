var ready = function() {
  if ($(".users")[0] && $('#new_user')[0]){
    $(".send_sms").click(function () {
      var user_id = $(this).data('user-id');
      console.log("user_id="+user_id);
      var href = $("#url_template").val();
      $(".modal-footer a").attr("href", href.replace("%7Buser_id%7D", user_id));
      console.log("href="+$(".modal-footer a").attr("href"));
    });

    $("#save_user").click(function(e){
      var form = $('#new_user');
      if (form[0].checkValidity()) {
        e.preventDefault();
        $('#createUserModal').modal('show');
      }
    });

    $("#send_now").click(function () {
      $("#user_send_sms").val("1");
      $('#new_user').submit();
    });

    $("#send_later").click(function () {
      $("#user_send_sms").val("0");
      $('#new_user').submit();
    });
  }
};

$(document).ready(ready);
$(document).on('page:load', ready);
