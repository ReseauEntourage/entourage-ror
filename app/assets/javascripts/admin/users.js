var ready = function() {
  if ($(".admin.users")[0]) {
    $("#sms_group").hide();
    $("#sms_group :input")[0].setAttribute("disabled", "disabled");
    $("#sms_group :input").val("");
    $("#change_password").click(function() {
      $("#sms_group").show();
      $("#sms_group :input")[0].removeAttribute("disabled");
    });
  }
};

$(document).ready(ready);
$(document).on('page:load', ready);