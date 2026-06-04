import consumer from "channels/consumer"

if (!consumer) {
  // Pas de token (ex: page de login) — pas de connexion WebSocket
} else {
  consumer.subscriptions.create("NotificationChannel", {
    connected() {
      console.log("[ActionCable] NotificationChannel connecté")
      document.dispatchEvent(new CustomEvent("cable:notifications:connected"))
    },

    disconnected() {
      console.log("[ActionCable] NotificationChannel déconnecté")
    },

    received(data) {
      console.log("[ActionCable] Notification reçue :", data)
      showNotificationToast(data.message, data.type || "info")
      incrementNotificationBadge()
    }
  })
}

function showNotificationToast(message, type) {
  var container = document.getElementById("cable-notifications")
  if (!container) return

  var alertClass = type === "danger"  ? "alert-danger"
                 : type === "success" ? "alert-success"
                 : type === "warning" ? "alert-warning"
                 : "alert-info"

  var toast = document.createElement("div")
  toast.className = "alert " + alertClass + " alert-dismissible"
  toast.setAttribute("role", "alert")

  var closeBtn = document.createElement("button")
  closeBtn.type = "button"
  closeBtn.className = "close"
  closeBtn.setAttribute("data-dismiss", "alert")
  closeBtn.innerHTML = "<span>&times;</span>"

  var text = document.createTextNode(message)
  toast.appendChild(closeBtn)
  toast.appendChild(text)

  container.appendChild(toast)
  setTimeout(function() { $(toast).alert("close") }, 6000)
}

function incrementNotificationBadge() {
  var badge = document.getElementById("cable-notif-count")
  if (!badge) return
  var count = parseInt(badge.dataset.count || "0", 10) + 1
  badge.dataset.count = count
  badge.textContent = count
  badge.style.display = "inline"
}
