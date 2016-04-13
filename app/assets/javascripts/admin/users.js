var ready = function() {
  if ($(".admin.users.new")[0] || $(".admin.users.edit")[0] || $(".admin.users.update")[0] || $(".admin.ambassadors.new")[0] || $(".admin.ambassadors.edit")[0] || $(".admin.ambassadors.update")[0]) {
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