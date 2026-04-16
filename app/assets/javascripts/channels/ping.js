(function() {
  if (!window.App) return;

  App.ping = App.cable.subscriptions.create("PingChannel", {
    connected: function() {
      console.log("Connected to PingChannel");
      this.perform('ping');
    },
    disconnected: function() {
      console.log("Disconnected from PingChannel");
    },
    received: function(data) {
      console.log("Received from PingChannel:", data);
    }
  });
}).call(this);
