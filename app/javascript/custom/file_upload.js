var ready = function() {
  if($(".users.step3")[0]) {
    var form         = $('#edit_user');
    var fileInput    = $('#upload-logo');
    var submitButton = form.find("input[type='submit']");
    var progressBar  = $("<div class='bar'></div>");
    var barContainer = $("<div class='progress'></div>").append(progressBar);
    var fd           = JSON.parse(form.attr("data-form-data"));
    fileInput.parent().after(barContainer);

    if(fileInput[0]) {
      //see https://github.com/blueimp/jQuery-File-Upload/wiki/Options
      fileInput.fileupload({
        add: function (e, data) {
          fd["Content-Type"] = data.files[0].type;
          data.formData = fd;
          data.submit();
        },
        fileInput: fileInput,
        url: form.data('url'),
        type: 'POST',
        autoUpload: true,
        formData: form.data('form-data'),
        paramName: 'file', // S3 does not like nested name fields i.e. name="user[avatar_url]"
        dataType: 'XML',  // S3 returns XML if success_action_status is set to 201
        replaceFileInput: false,
        progressall: function (e, data) {
          console.log('progress');
          var progress = parseInt(data.loaded / data.total * 100, 10);
          progressBar.css('width', progress + '%')
        },
        start: function (e) {
          console.log('start');
          submitButton.prop('disabled', true);

          progressBar.addClass('is-loading').text("Loading...");
        },
        done: function (e, data) {
          console.log('done');
          submitButton.prop('disabled', false);
          progressBar.removeClass('is-loading').addClass('is-loaded').text("Photo enregistrée !");

          // extract key from response
          var key = $(data.jqXHR.responseXML).find("Key").text();
          $('#file-key').val(key);
        },
        fail: function (e, data) {
          console.log('failed' + data.errorThrown);
          submitButton.prop('disabled', false);

          progressBar.css("background", "red").text("Failed");
        }
      });
    }
  }
};

$(document).ready(ready);
$(document).on('page:load', ready);
