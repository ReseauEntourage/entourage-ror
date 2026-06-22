pin "application", preload: true

# jQuery, Turbolinks → globals via <script> dans _head.html.erb
# Plugins UMD (moment, daterangepicker, multiselect…) → Sprockets plugins.js (defer)

# @rails/ujs est inclus dans plugins.js (Sprockets, jquery_ujs) — compatible jQuery global

# ActionCable (servi par le gem Rails)
pin "actioncable", to: "actioncable.esm.js"

# Chartkick + Chart.js (chart.umd utilise window, pas this — compatible ES module)
pin "chartkick", to: "https://cdn.jsdelivr.net/npm/chartkick@5.0.1/dist/chartkick.esm.js"
pin "chart.js",  to: "https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"

# TinyMCE (CDN - remplacer "no-api-key" par la vraie clé en prod)
pin "tinymce", to: "https://cdn.tiny.cloud/1/no-api-key/tinymce/6/tinymce.min.js"

# Fichiers locaux app/javascript/ — pinned pour obtenir les URLs fingerprinted en production
# (les imports relatifs "./common" → 404 en prod car Sprockets ne sert que les URLs fingerprintées)
pin "common"
pin "users"
pin "organization"
pin "file_upload"
pin "tour"
pin "users_autocomplete"
pin "admin/users", to: "admin/users.js"

# ActionCable channels
pin_all_from "app/javascript/channels", under: "channels"
