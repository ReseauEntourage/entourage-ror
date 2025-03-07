var ready = function() {
  if ($(".admin.users.new")[0] || $(".admin.users.create")[0] || $(".admin.users.edit")[0] || $(".admin.users.update")[0]) {
    $("#sms_group").hide();
    $("#sms_group :input")[0].setAttribute("disabled", "disabled");
    $("#sms_group :input").val("");
    $("#change_password").click(function(e) {
      e.preventDefault();
      $("#change_password").hide();
      $("#sms_group").show();
      $("#sms_group :input")[0].removeAttribute("disabled");
      $("#admin-user-update").attr('value', 'Enregistrer et envoyer la confirmation');
    });

    function requireProAttributes(require) {
      ['first_name', 'last_name', 'email'].forEach(function(attr) {
        $('[name="user[' + attr + ']"]').attr('required', require);
      });
    }

    $("#pro_user").on('change', function() {
      requireProAttributes(this.value !== '');
    });
  }
};

$(document).ready(ready);
$(document).on('page:load', ready);
