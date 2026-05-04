import consumer from "./consumer"

consumer.subscriptions.create("TestChannel", {
  connected() {
    console.log("Connected to TestChannel")
    this.perform("ping", { test: "data" })
  },

  disconnected() {
    console.log("Disconnected from TestChannel")
  },

  received(data) {
    console.log("Received data from TestChannel:", data)
  }
})
