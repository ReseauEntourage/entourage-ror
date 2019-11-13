// inspired from https://github.com/rails/jquery-ujs/blob/master/src/rails.js
(function() {
  'use strict';

  function allowAction(element) {
    var message = element.data('confirm'),
        answer = false;

    if (!message) { return true; }

    try {
      answer = confirm(message);
    } catch (e) {
      (console.error || console.log).call(console, e.stack || e);
    }

    return answer;
  }

  function init() {
    var confirmSelector = '[data-confirm]';
    $(document).on('click.confirm', confirmSelector, function(e) {
      if (!allowAction($(this))) {
        e.stopImmediatePropagation();
        e.preventDefault();
      }
    });
  }

  if (window.jQuery) {
    init();
  }
})();
