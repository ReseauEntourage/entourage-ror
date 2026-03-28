import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = [ "messages" ]

  connect() {
    this.channel = createConsumer().subscriptions.create("PingChannel", {
      received: (data) => {
        this.appendMessage(data.message)
      }
    })
    console.log("Connected to PingChannel")
  }

  disconnect() {
    if (this.channel) {
      this.channel.unsubscribe()
    }
  }

  appendMessage(message) {
    const element = document.createElement("div")
    element.textContent = `Received: ${message} at ${new Date().toLocaleTimeString()}`
    this.messagesTarget.appendChild(element)
  }
}
