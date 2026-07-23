// Bundle Sprockets de tous les plugins jQuery UMD.
// Chargé en synchrone/bloquant avant les modules ES (importmap) et avant les
// <script> inline des vues (select2(), <%= tinymce %>...).
// Ici, this === window — les UMD fonctionnent correctement.
//= require jquery_ujs
//= require moment
//= require daterangepicker
//= require bootstrap-multiselect
//= require bootstrap4-toggle.min
//= require bootstrap-tagsinput.min
//= require select2
//= require jquery.ui.widget
//= require jquery.fileupload
//= require jquery-ui/datepicker
//= require jquery-ui/datepicker-fr
//= require jquery-ui/autocomplete

// TinyMCE auto-hébergé (gem tinymce-rails) : définit window.TinyMCERails
// et window.tinymce, requis par <%= tinymce %> dans les vues admin.
//= require tinymce
