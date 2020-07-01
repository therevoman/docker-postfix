
FROM alpine:latest

RUN true && \
    apk add --no-cache bash bats && \
    apk add --no-cache --upgrade cyrus-sasl cyrus-sasl-plain cyrus-sasl-login && \
    apk add --no-cache postfix && \
    apk add --no-cache opendkim && \
    (rm "/tmp/"* 2>/dev/null || true) && (rm -rf /var/cache/apk/* 2>/dev/null || true)

WORKDIR /code
ENTRYPOINT ["/usr/bin/bats"]

CMD ["-v"]