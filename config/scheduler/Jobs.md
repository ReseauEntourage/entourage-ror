# Jobs

The job engine uses 2 tools:

- whenever (https://github.com/javan/whenever)
- supercronic (https://github.com/aptible/supercronic)

## How it works

1. You define using `whenever` syntax in ruby the tasks you want to run, and then base on the environment we will run 
the correct jobs files

`whenever` creates a crontab file that can be executed by `supertronic`

2. `supertronic` runs the file as a foreground process (cron is not made for docker, this is why we us this library)

## Which file is run

The file chosen is determined by the env variable `JOB_FILE`. This is how we choose which job file is run for 
an environment.