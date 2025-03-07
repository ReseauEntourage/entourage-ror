var ready = function() {
  $(function() {
    $("#user_relations").autocomplete({
      source: function( request, response ) {
        $.ajax({
          url: "/admin/public_user_autocomplete",
          dataType: "json",
          delay: 250,
          data: {
            search: request.term
          },
          success: function( data ) {
            response( data.users_search );
          }
        });
      },
      minLength: 2,
      select: function( event, ui ) {
        if(ui.item) {
          $("#user_relation_id").val(ui.item.id);
        }
      }
    });
  });
};

$(document).ready(ready);
$(document).on('page:load', ready);
