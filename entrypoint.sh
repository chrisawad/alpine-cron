#!/bin/bash

printenv > /etc/environment

if [ "$CRON_CONFIG" = "true" ]
then
	echo "$CRON_MINUTE $CRON_HOUR $CRON_MONTH_DAY $CRON_MONTH $CRON_WEEK_DAY $CRON_WRAPPER \"$CRON_SCRIPT\" > /proc/1/fd/1 2> /proc/1/fd/2" > $CRON_FILE
fi

if [ ! -f $CRON_FILE ]
then
	echo "Please mount $CRON_FILE or set CRON_CONFIG=true and set CRON_{MINUTE,HOUR,MONTH_DAY,MONTH,WEEK_DAY}"
	exit 1
fi

cat $CRON_FILE
crontab $CRON_FILE

exec "$@"
