(function() {
  var setupPingSubscription = function() {
    if (!window.App || !window.App.cable) {
      console.log("ActionCable consumer not found, skipping subscription setup.");
      return;
    }

    if (window.App.pingSubscription) {
      console.log("PingSubscription already exists, skipping.");
      return;
    }

    console.log("Creating subscription to PingChannel...");
    window.App.pingSubscription = window.App.cable.subscriptions.create("PingChannel", {
      connected: function() {
        console.log("PingChannel: Connected!");
        var status = document.getElementById('ping-status');
        if (status) { status.innerText = 'Connected'; status.style.color = 'green'; }
      },
      disconnected: function() {
        console.log("PingChannel: Disconnected");
        var status = document.getElementById('ping-status');
        if (status) { status.innerText = 'Disconnected'; status.style.color = 'red'; }
      },
      received: function(data) {
        console.log("PingChannel: Received data:", data);
        var messagesDiv = document.querySelector('[data-ping-target="messages"]');
        if (messagesDiv) {
          var messageElement = document.createElement('p');
          messageElement.innerHTML = '<strong>' + new Date().toLocaleTimeString() + ':</strong> ' + data.message;
          messagesDiv.prepend(messageElement);
        }
      }
    });
  };

  // Subscribe on initial load and on Turbo page changes
  document.addEventListener('turbo:load', setupPingSubscription);

  // Also try immediately if document is already loaded
  if (document.readyState !== 'loading') {
    setupPingSubscription();
  } else {
    document.addEventListener('DOMContentLoaded', setupPingSubscription);
  }
}).call(this);
