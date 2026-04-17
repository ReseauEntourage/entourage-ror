(function() {
  var setupSubscription = function() {
    if (!window.App || !window.App.cable) {
      console.log("App.cable not found, retrying...");
      setTimeout(setupSubscription, 100);
      return;
    }

    window.App.cable.subscriptions.create("PingChannel", {
      connected: function() {
        console.log("PingChannel: connected");
      },
      disconnected: function() {
        console.log("PingChannel: disconnected");
      },
      received: function(data) {
        console.log("PingChannel: received", data);
        var messagesDiv = document.querySelector('[data-ping-target="messages"]');
        if (messagesDiv) {
          var messageElement = document.createElement('p');
          messageElement.innerHTML = '<strong>' + new Date().toLocaleTimeString() + ':</strong> ' + data.message;
          messagesDiv.prepend(messageElement);
        }
      }
    });
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', setupSubscription);
  } else {
    setupSubscription();
  }
}).call(this);
