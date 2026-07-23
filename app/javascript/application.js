// Plugins jQuery UMD (moment, daterangepicker, multiselect, jquery_ujs, tinymce…) :
//   chargés en bloquant via Sprockets plugins.js AVANT ce module.
//   window.$, window.jQuery.rails (UJS), $.fn.multiselect, window.TinyMCERails, etc.
//   sont déjà disponibles ici.

// App JS — bare imports résolus via importmap → URLs fingerprinted en production
import "common"
import "users"
import "organization"
import "file_upload"
import "tour"
import "users_autocomplete"
import "admin/users"

// Charts (ESM natif ou UMD qui utilise window, pas this)
import "chart.js"
import "chartkick"

// ActionCable
import "channels/consumer"
import "channels/notifications_channel"
