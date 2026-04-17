(function() {
  window.App = window.App || {};
  if (!window.App.cable) {
    console.log("[ActionCable] Initializing consumer...");
    window.App.cable = ActionCable.createConsumer();
  }
}).call(this);
