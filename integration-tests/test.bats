#!/usr/bin/env bats

FROM=$1
TO=$2

if [ -z "$FROM" ]; then
    FROM="demo@example.org"
fi

if [ -z "$TO" ]; then
    TO="test@gmail.com"
fi

# Wait for postfix to startup
echo "Waiting for startup..."
wait-for-service -q tcp://postfix_test_587:587

SMTP_DATA="-smtp postfix_test_587 -port 587"

@test "Get server info" {
	mailsend -info $SMTP_DATA
}

@test "Send a simple mail" {
	mailsend \
		-sub "Test email 1" $SMTP_DATA \
			-from "$FROM" -to "$TO" \
		body \
			-msg "Hello world!\nThis is a simple test message!"
}

@test "Send mail with attachment" {
	mailsend \
		-sub "Test with attachment" $SMTP_DATA \
			-from "$FROM" -to "$TO" \
		body \
			-msg "Hi!\nThis is an example of an attachment." \
		attach \
			-file "/usr/local/bin/mailsend"
}
