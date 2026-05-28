// Plugins jQuery UMD (moment, daterangepicker, multiselect…) :
//   chargés via Sprockets plugins.js (defer) AVANT ce module.
//   window.$, window.moment, $.fn.multiselect, etc. sont déjà disponibles ici.

import "@rails/ujs"

// App JS (code jQuery plain — utilisent window.$ global)
import "./common"
import "./users"
import "./organization"
import "./file_upload"
import "./tour"
import "./users_autocomplete"
import "./admin/users"

// Charts (ESM natif ou UMD qui utilise window, pas this)
import "chart.js"
import "chartkick"

// TinyMCE
import "tinymce"

// ActionCable
import "channels/consumer"
import "channels/notifications_channel"
