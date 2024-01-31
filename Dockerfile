FROM alpine
ENV TZ=America/New_York
ENV CRON_CONFIG=true
ENV CRON_MINUTE=0
ENV CRON_HOUR=3
ENV CRON_MONTH_DAY=*
ENV CRON_MONTH=*
ENV CRON_WEEK_DAY=*
ENV CRON_SCRIPT=/script.sh
ENV CRON_FILE=/cron_file
ENV CRON_WRAPPER=/wrapper.sh
ENV CRON_AFTER=/after.sh
RUN apk add --no-cache bash apk-cron git openssh-client postgresql-client pigz tzdata pv s-nail curl python3 
RUN apk add --no-cache py3-sqlalchemy py3-pandas py3-psycopg2 py3-openpyxl py3-paramiko py3-requests py3-mysqlclient
COPY entrypoint.sh /entrypoint.sh
COPY wrapper.sh /wrapper.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["crond", "-f", "-d", "8"]
