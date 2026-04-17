import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = [ "messages", "status" ]

  connect() {
    const url = document.querySelector("meta[name='action-cable-url']")?.content || "/cable"
    console.log("[PingController] Connecting to:", url)
    this.updateStatus("Connecting...", "orange")

    try {
      this.consumer = createConsumer(url)
      this.channel = this.consumer.subscriptions.create("PingChannel", {
        connected: () => {
          console.log("[PingController] CONNECTED")
          this.updateStatus("Connected", "green")
        },
        disconnected: () => {
          console.warn("[PingController] DISCONNECTED")
          this.updateStatus("Disconnected", "red")
        },
        received: (data) => {
          console.log("[PingController] RECEIVED:", data)
          this.appendMessage(data.message)
        }
      })
    } catch (e) {
      console.error("[PingController] Connection error:", e)
      this.updateStatus("Error: " + e.message, "red")
    }
  }

  disconnect() {
    if (this.channel) this.channel.unsubscribe()
    if (this.consumer) this.consumer.disconnect()
  }

  updateStatus(text, color) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = text
      this.statusTarget.style.color = color
    }
  }

  appendMessage(message) {
    const p = document.createElement("p")
    p.style.margin = "5px 0"
    p.style.padding = "5px"
    p.style.borderBottom = "1px solid #eee"
    p.innerHTML = "<strong>" + new Date().toLocaleTimeString() + ":</strong> " + message
    this.messagesTarget.prepend(p)
  }
}
