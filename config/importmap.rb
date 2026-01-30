pin "application", preload: true
pin "@rails/actioncable", to: "actioncable.esm.js", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/admin", under: "admin"
pin_all_from "app/javascript/templates", under: "templates"

pin "jquery", to: "https://ga.jspm.io/npm:jquery@3.7.1/dist/jquery.js"
pin "jquery-ujs", to: "https://ga.jspm.io/npm:jquery-ujs@1.2.3/src/rails.js"
pin "jquery-ui", to: "https://ga.jspm.io/npm:jquery-ui-dist@1.13.2/jquery-ui.js"
pin "moment", to: "https://ga.jspm.io/npm:moment@2.30.1/moment.js"
pin "daterangepicker", to: "daterangepicker.js"
pin "bootstrap-multiselect", to: "bootstrap-multiselect.js"
pin "jquery.fileupload", to: "jquery.fileupload.js"
pin "jquery.ui.widget", to: "jquery.ui.widget.js"
pin "select2", to: "https://ga.jspm.io/npm:select2@4.1.0-rc.0/dist/js/select2.js"
pin "chartkick", to: "chartkick.js"
pin "Chart.bundle", to: "Chart.bundle.js"
pin "tinymce", to: "https://ga.jspm.io/npm:tinymce@6.8.2/tinymce.js"
pin "handlebars", to: "https://ga.jspm.io/npm:handlebars@4.7.8/dist/handlebars.js"

pin "bootstrap-tagsinput", to: "bootstrap-tagsinput.min.js"
pin "bootstrap4-toggle", to: "bootstrap4-toggle.min.js"
pin "common", to: "common.js"
pin "file_upload", to: "file_upload.js"
pin "organization", to: "organization.js"
pin "tour", to: "tour.js"
pin "users", to: "users.js"
pin "users_autocomplete", to: "users_autocomplete.js"
