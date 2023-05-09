#!/bin/bash

exec > >(tee last.result) 2>&1

START=$(date +%s)
TS=$(date -ud @$START)

echo "=====================================
STARED: $TS"
$1
CODE=$?

END=$(date +%s)
DIFF=$(($END-$START))
DURATION=$(date +'%H hr %M min %S sec' -ud @$DIFF)
[ $CODE -eq 0 ] && STATUS="SUCCESS" || STATUS="FAILURE"

echo "RESULT: $STATUS - $DURATION"

if [ -f $CRON_AFTER ]
then
	echo "- AFTER SCRIPT:"
	$CRON_AFTER
fi
echo "====================================="

exit $CODE
