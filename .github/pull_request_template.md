## Summary

<!-- What changes and why. Link the Jira ticket and the entourage-specs PR when there are some. -->

## Checks

- [ ] The tests of what changed pass (`bundle exec rspec <path>`)
- [ ] No route of the apps changes (or the versions already installed keep working)
- [ ] A migration, if any, is additive and does not lock a big table
- [ ] A new environment variable is in `.env.dist` and in the README
- [ ] No secret, no message content and no personal data in the code, the logs or Sentry
- [ ] **Personal data added to the data sent to the AI** (the routes of `/api/v1/assistant`, what the assistant reads or receives): none, or the DPO and the Local team reviewed each new field
