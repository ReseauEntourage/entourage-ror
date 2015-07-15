var hooks = require('hooks');

hooks.before("Users > User actions > Login user", function(transaction) {
  if (transaction.request['headers']['Content-Type'] === 'application/x-www-form-urlencoded; charset=utf-8') {
    transaction.request['body'] = transaction.request['body'].replace(/^\s+|\s+$/g, "");
  }
});
