(function() {
  var updateUI = function(status, color) {
    var statusEl = document.getElementById('ping-status');
    if (statusEl) {
      statusEl.innerText = status;
      statusEl.style.color = color;
    }
  };

  var setupPingSubscription = function() {
    if (!document.getElementById('ping-container')) return;

    console.log("[PingDemo] Setup initiated");

    if (!window.App || !window.App.cable) {
      console.warn("[PingDemo] App.cable not ready, retrying...");
      setTimeout(setupPingSubscription, 500);
      return;
    }

    if (window.App.pingSubscription) {
      console.log("[PingDemo] Subscription exists. Current state:", window.App.cable.connection.state);
      // Update UI for current page
      if (window.App.cable.connection.isOpen()) {
        updateUI("Connected", "green");
      } else {
        updateUI("Connecting...", "orange");
      }
      return;
    }

    console.log("[PingDemo] Creating new subscription to PingChannel");
    window.App.pingSubscription = window.App.cable.subscriptions.create("PingChannel", {
      connected: function() {
        console.log("[PingDemo] Callback: connected");
        updateUI("Connected", "green");
      },
      disconnected: function() {
        console.log("[PingDemo] Callback: disconnected");
        updateUI("Disconnected", "red");
      },
      rejected: function() {
        console.log("[PingDemo] Callback: rejected");
        updateUI("Rejected", "red");
      },
      received: function(data) {
        console.log("[PingDemo] Callback: received", data);
        var messagesDiv = document.querySelector('[data-ping-target="messages"]');
        if (messagesDiv) {
          var p = document.createElement('p');
          p.innerHTML = '<strong>' + new Date().toLocaleTimeString() + ':</strong> ' + data.message;
          messagesDiv.prepend(p);
        }
      }
    });
  };

  document.addEventListener('turbo:load', setupPingSubscription);
  if (document.readyState !== 'loading') setupPingSubscription();
  else document.addEventListener('DOMContentLoaded', setupPingSubscription);
})();
