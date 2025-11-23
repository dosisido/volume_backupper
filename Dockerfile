FROM alpine

RUN apk add --no-cache bash zip dcron
USER root

COPY backup.sh /app/run.sh
RUN chmod +x /app/run.sh
COPY scheduler.sh /app/scheduler.sh
RUN chmod +x /app/scheduler.sh

CMD /app/scheduler.sh