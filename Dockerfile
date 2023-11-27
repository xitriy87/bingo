FROM alpine
RUN addgroup -g 1000 bingo && adduser -S -u 1000 -G bingo bingo -h /opt/bingo/ && mkdir -p /opt/bongo/logs/359c71e299 && chown -R bingo:bingo /opt/bongo && apk add curl && rm -rf /var/cache/apk/*
USER 1000
WORKDIR /opt/bingo/
COPY bingo .
COPY config.yaml .
EXPOSE 20061
#HEALTHCHECK --interval=10s --timeout=10s --start-period=80s  CMD curl -I -X GET http://localhost:20061/ping || exit 1
CMD ["/bin/sh","-c","./bingo prepare_db ; ./bingo run_server"]
