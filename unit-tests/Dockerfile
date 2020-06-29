
FROM alpine:latest

RUN apk add --no-cache bash bats

WORKDIR /code
ENTRYPOINT ["/usr/bin/bats"]

CMD ["-v"]