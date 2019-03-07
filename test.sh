#!/bin/sh
docker build . -t boky/postfix
docker-compose up -d

FROM=$1
TO=$2

# Wait for postfix to startup
echo "Waiting for startup..."
while ! docker ps | fgrep postfix_test_587 | grep -q healthy; do 
    sleep 1
done

cat <<EOF | nc -C localhost 1587
HELO test
MAIL FROM:$FROM
RCPT TO:$TO
DATA
Subject: Postfix message test
From: $FROM
To: $TO
Date: $(date)
Content-Type: text/plain

This is a simple text of message sending using boky/postfix.
.
QUIT
EOF

# Wait for email to be delivered
echo "Waiting to shutdown..."
sleep 5

# Shut down tests
docker-compose down

