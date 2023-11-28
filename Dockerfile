FROM alpine
RUN addgroup -g 1000 bingo && adduser -S -u 1000 -G bingo bingo -h /opt/bingo/ && mkdir -p /opt/bongo/logs/359c71e299 && chown -R bingo:bingo /opt/bongo && apk add curl && rm -rf /var/cache/apk/*
USER 1000
WORKDIR /opt/bingo/
COPY bingo .
COPY config.yaml .
EXPOSE 20061
CMD ["/bin/sh","-c","./bingo prepare_db ; ./bingo run_server"]
