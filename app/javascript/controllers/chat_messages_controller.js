import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static values = {
    messageableId: String,
    messageableType: String
  }

  static targets = ["list"]

  connect() {
    this.channel = createConsumer().subscriptions.create(
      {
        channel: "ChatMessagesChannel",
        messageable_id: this.messageableIdValue,
        messageable_type: this.messageableTypeValue
      },
      {
        received: (data) => {
          this.appendMessage(data)
        }
      }
    )
  }

  disconnect() {
    this.channel.unsubscribe()
  }

  appendMessage(data) {
    // This is a simple implementation. In a real app, you'd probably use a template.
    // Since we don't have a JS template engine here, we'll just append a simple div or reload.
    // Ideally, we would render the partial on the server and broadcast the HTML.
    // For now, let's just log and maybe do a simple append or reload.
    console.log("New message received:", data)
    // To properly render the message, we might need more info or a reload.
    // If we want to avoid reload, we need the HTML.
    // Let's assume for now we just want to show it's working.
    location.reload()
  }
}
