(function() {
  App.cable.subscriptions.create("WebNotificationsChannel", {
    connected: function() {
      // Called when the subscription is ready for use on the server
      console.log("Connected to WebNotificationsChannel");
    },

    disconnected: function() {
      // Called when the subscription has been terminated by the server
      console.log("Disconnected from WebNotificationsChannel");
    },

    received: function(data) {
      // Called when there's incoming data on the websocket for this channel
      console.log("Received data from WebNotificationsChannel:", data);
    }
  });
}).call(this);
