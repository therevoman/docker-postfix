ARG ALPINE_VERSION=latest
FROM alpine:${ALPINE_VERSION}
LABEL maintaner="Bojan Cekrlic - https://github.com/bokysan/docker-postfix/"

RUN        true && \
           apk add --no-cache --upgrade cyrus-sasl cyrus-sasl-plain cyrus-sasl-login && \
           apk add --no-cache postfix && \
           apk add --no-cache opendkim && \
           apk add --no-cache --upgrade ca-certificates tzdata supervisor rsyslog musl musl-utils bash opendkim-utils && \
           (rm "/tmp/"* 2>/dev/null || true) && (rm -rf /var/cache/apk/* 2>/dev/null || true)
RUN        apk add --no-cache bash bats && \
           (rm "/tmp/"* 2>/dev/null || true) && (rm -rf /var/cache/apk/* 2>/dev/null || true)

WORKDIR    /code
ENTRYPOINT ["/usr/bin/bats"]

CMD        ["-v"]