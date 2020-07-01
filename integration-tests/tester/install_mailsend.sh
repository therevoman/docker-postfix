#!/usr/bin/env bash
set -e

install_mailsend() {
	local ARCH="$(uname -m)"
	local MAILSEND_VERSION="1.0.9"

	if [[ "$ARCH" == "x86_64" ]]; then
		ARCH="64bit"
	else
		ARCH="ARM"
	fi

	cd /tmp
	curl -LsS https://github.com/muquit/mailsend-go/releases/download/v${MAILSEND_VERSION}/mailsend-go_${MAILSEND_VERSION}_linux-${ARCH}.tar.gz | tar xzfv -
	chmod +x /tmp/mailsend-go-dir/mailsend-go
}

install_mailsend
