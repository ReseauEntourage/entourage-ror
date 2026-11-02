# Sourced by the Datadog buildpack once the agent configuration is written and
# right before the agent starts, on every dyno (one-off dynos included):
# https://docs.datadoghq.com/agent/basic_agent_usage/heroku/#prerun-script

# One agent is enough to monitor the shared Postgres database: each agent
# running the Postgres check (Database Monitoring included) polls
# pg_stat_statements and pg_stat_activity on its own. Keep the check on web.1
# only. An app that must not monitor the database at all leaves
# DD_ENABLE_HEROKU_POSTGRES unset.
if [ "$DYNO" != "web.1" ]; then
  rm -f "$DD_CONF_DIR/conf.d/postgres.d/conf.yaml"
fi
