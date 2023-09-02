FROM restic/restic:0.16.0

RUN apk add --update --no-cache curl

# /data is the dir where you have to put the data to be backed up
VOLUME /data

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]