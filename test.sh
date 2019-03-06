#!/bin/sh
docker build . -t boky/postfix
docker-compose up -d

# Wait for postfix to startup
echo "Waiting for startup..."
while ! docker ps | fgrep postfix_test_587 | grep -q healthy; do 
    sleep 1
done

cat <<"EOF" | nc -C localhost 1587
HELO test
MAIL FROM:test@example.org
RCPT TO:check-auth@verifier.port25.com
DATA
Subject: Postfix message test
From: test@example.org
To: check-auth@verifier.port25.com
Date: Wed, 06 Mar 19 09:40:08 +0000
Content-Type: text/plain

This is a simple text
.
QUIT
EOF

# Wait for email to be delivered
echo "Waiting to shutdown..."
sleep 5

# Shut down tests
docker-compose down

