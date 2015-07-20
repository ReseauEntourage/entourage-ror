var hooks = require('hooks');

hooks.before("Users > Users collection > Retrieve all users", function(transaction) {
  transaction.request['headers']['Authorization'] = 'Basic YWRtaW46M250MHVyNGcz'
});

hooks.before("Users > Users collection > Create a user", function(transaction) {
  transaction.request['headers']['Authorization'] = 'Basic YWRtaW46M250MHVyNGcz'
});

hooks.before("Users > User > Update user", function(transaction) {
  transaction.request['headers']['Authorization'] = 'Basic YWRtaW46M250MHVyNGcz'
});

hooks.before("Users > User > Delete user", function(transaction) {
  transaction.request['headers']['Authorization'] = 'Basic YWRtaW46M250MHVyNGcz'
});
