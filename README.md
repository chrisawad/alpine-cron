# alpine-cron
Run cron tasks in docker. It's pretty simple. Specify the cron schedule and bash script to execute in docker-compose.yml, and `docker compose up -d`

For convivence this alpine image contains bash, git, openssh-client, postgresql-client and tzdata.

Note, the TZ env variable must be set according to the Time Zone you wish to use for CRON_HOUR. TZ=America/New_York is the default, so CRON_HOUR will be expected to be in EST if it is not changed.

Here's a docker-compose.yml with all the default env variables (as set in the Dockerfile). If you exclude all variables, the script will run at 3am, daily by default.

```
version: "3.7"
services:
  cron:
    image: cawad/alpine-cron:latest
    environment:
      - TZ=America/New_York
      - CRON_CONFIG=true
      - CRON_MINUTE=0
      - CRON_HOUR=3
      - CRON_MONTH_DAY=*
      - CRON_MONTH=*
      - CRON_WEEK_DAY=*
      - CRON_SCRIPT=/script.sh
      - CRON_FILE=/cron_file
      - CRON_WRAPPER=/wrapper.sh
      - CRON_AFTER=/after.sh
    volumes:
      - ./script.sh:/script.sh
    init: true
```
Notice init: true, here. In order to properly reap forks, we must tell docker to use the the tini init system.

Here is a minimal configuration that runs the script daily at 8:15 AM EST, while utilizing many of the defaults:
```
version: "3.7"
services:
  cron:
    image: cawad/alpine-cron:latest
    environment:
      - CRON_MINUTE=15
      - CRON_HOUR=8
    volumes:
      - ./script.sh:/script.sh
    init: true
```

Here is the output that the wrapper.sh script prints out when the schedule is run (with CRON_CONFIG=true):
```
=====================================
STARED: Tue Sep 20 17:45:28 UTC 2022
<output of script>
RESULT: SUCCESS - 00 hr 00 min 01 sec
======================================
```
RESULT will indicate SUCCESS or FAILURE based on the scripts exit code, and the time it took for the script to run to completion or failure.

You can also print or get the last result from inside the running container via  `docker compose exec cron cat last.result`, otherwise `docker compose logs` will contain the running logs.

CRON_CONFIG=true automatically generates this cron_file based on the parameters provider in docker-compose.yml or .env:
```
0 3 * * * /wrapper.sh "/script.sh" > /proc/1/fd/1 2> /proc/1/fd/2
```

You can always set CRON_CONFIG=false and and instead provide your own cron_file, but this will not use the internal wrapper.sh and after.sh scripts unless you do something similar to the above and wrap your script with /wrapper.sh. In order to redirect the script output to docker logs, you must add `> /proc/1/fd/1 2> /proc/1/fd/2"`, as well.

**It is recommended that you spin up multiple containers, each with one script and schedule, instead of having to worry about creating your own cron_file**


Example:

Let's tar up a directory on a remote server (over SSH) and store it onto this server's mounted storage, while pruning all but 30 of the latest backups:

Note: this mounts the host's ssh keys into the container for passwordless ssh and uses configuration provided by additional env variables, which are made useful only by the provided backup script. Using this we can backup multiple remote directories on different schedules by simply adding more services with different env variables. In this case, I am backing up the data directory on a remote docker registry to remote storage mounted onto the host filesystem.

docker-compose.yml:
```
version: "3.7"
services:
        backup:
                image: cawad/alpine-cron:latest
                environment:
                        - CRON_MINUTE=15
                        - CRON_HOUR=3
                        - SSH_HOST=root@192.168.1.100
                        - SSH_CD=/root/docker/registry/data
                        - SSH_TARGET=docker
                        - BACKUP_PREFIX=registry
                        - BACKUP_DIR=/backups
                        - BACKUP_KEEP=30
                volumes:
                        - ./ssh_tar.sh:/script.sh
                        - /root/.ssh:/root/.ssh
                        - /mnt/storage:/backups
                init: true
```

ssh_tar.sh:
```
#!/bin/bash

TARGET=${BACKUP_PREFIX}_$(date +%Y%m%d_%H%M%S).tgz

cd ${BACKUP_DIR}
ssh -o "StrictHostKeyChecking no" ${SSH_HOST} "cd ${SSH_DIR} && tar czvf - ${SSH_TARGET}" > $TARGET
rm -f $(ls -t ${BACKUP_PREFIX}_*.tgz | awk "NR>${BACKUP_KEEP}")
```
