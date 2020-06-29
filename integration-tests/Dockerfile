# ---- MAILSEND ----
FROM boky/alpine-bootstrap AS mailsend
COPY install_mailsend.sh /tmp/
RUN chmod +x /tmp/install_mailsend.sh && /tmp/install_mailsend.sh

# ---- TEST ----
FROM boky/alpine-bootstrap

RUN apk add --no-cache bash bats
COPY --from=mailsend /tmp/mailsend-go-dir/mailsend-go /usr/local/bin/mailsend

WORKDIR /code
ENTRYPOINT ["/usr/bin/bats"]

CMD ["-v"]
