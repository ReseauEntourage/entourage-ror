(function() {
  App.cable.subscriptions.create("PingChannel", {
    received: function(data) {
      var messagesDiv = document.querySelector('[data-ping-target="messages"]');
      if (messagesDiv) {
        var messageElement = document.createElement('p');
        messageElement.innerHTML = '<strong>' + new Date().toLocaleTimeString() + ':</strong> ' + data.message;
        messagesDiv.prepend(messageElement);
      }
    }
  });
}).call(this);
