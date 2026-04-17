import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = [ "messages", "status" ]

  connect() {
    console.log("[PingController] connecting...")
    this.channel = createConsumer().subscriptions.create("PingChannel", {
      connected: () => {
        console.log("[PingController] connected")
        this.updateStatus("Connected", "green")
      },
      disconnected: () => {
        console.log("[PingController] disconnected")
        this.updateStatus("Disconnected", "red")
      },
      received: (data) => {
        console.log("[PingController] received:", data)
        this.appendMessage(data.message)
      }
    })
  }

  disconnect() {
    if (this.channel) {
      this.channel.unsubscribe()
    }
  }

  updateStatus(text, color) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = text
      this.statusTarget.style.color = color
    }
  }

  appendMessage(message) {
    const element = document.createElement("p")
    element.innerHTML = '<strong>' + new Date().toLocaleTimeString() + ':</strong> ' + message
    this.messagesTarget.prepend(element)
  }
}
