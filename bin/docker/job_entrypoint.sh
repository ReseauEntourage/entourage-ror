#!/bin/bash

# we create the crontab file with cron instructions
whenever --load-file "$JOB_FILE" > crontab

# we run the scheduler using the scheduled jobs defined
supercronic -passthrough-logs -json crontab
