import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = [ "messages", "status" ]

  connect() {
    console.log("[PingController] Connecting...")
    this.channel = createConsumer().subscriptions.create("PingChannel", {
      connected: () => {
        console.log("[PingController] Connected!")
        this.updateStatus("Connected", "green")
      },
      disconnected: () => {
        this.updateStatus("Disconnected", "red")
      },
      received: (data) => {
        console.log("[PingController] Received:", data)
        this.appendMessage(data.message)
      }
    })
  }

  disconnect() {
    if (this.channel) this.channel.unsubscribe()
  }

  updateStatus(text, color) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = text
      this.statusTarget.style.color = color
    }
  }

  appendMessage(message) {
    const p = document.createElement("p")
    p.style.padding = "5px"
    p.style.borderBottom = "1px solid #eee"
    p.innerHTML = '<strong>' + new Date().toLocaleTimeString() + ':</strong> ' + message
    this.messagesTarget.prepend(p)
  }
}
