#!/usr/bin/env bats

load /code/scripts/common.sh
load /code/scripts/common-run.sh

if [[ ! -f /etc/postfix/main.test-multi-comment ]]; then
	cp /etc/postfix/main.cf /etc/postfix/main.test-multi-comment
fi

@test "make sure #myhostname appears four times in main.cf (default)" {
	result=$(grep -E "^#myhostname" /etc/postfix/main.cf | wc -l)
	[[ "$result" -gt 1 ]]
}

@test "make sure commenting out #myhostname does not incrase count" {
	COMMENT_COUNT=$(grep -E "^#myhostname" /etc/postfix/main.test-multi-comment | wc -l)
	do_postconf -# myhostname
	result=$(grep -E "^#myhostname" /etc/postfix/main.cf | wc -l)
	[ "$result" == "$COMMENT_COUNT" ]
}

@test "make sure adding myhostname does not incrase count" {
	COMMENT_COUNT=$(grep -E "^#myhostname" /etc/postfix/main.test-multi-comment | wc -l)
	do_postconf -e myhostname=localhost
	result=$(grep -E "^#myhostname" /etc/postfix/main.cf | wc -l)
	echo "result=$result"
	echo "COMMENT_COUNT=$COMMENT_COUNT"
	[ "$result" == "$COMMENT_COUNT" ]
}

@test "make sure adding myhostname is added only once" {
	do_postconf -e myhostname=localhost
	result=$(grep -E "^myhostname" /etc/postfix/main.cf | wc -l)
	[ "$result" == "1" ]
}

@test "make sure deleting myhostname does not incrase count" {
	COMMENT_COUNT=$(grep -E "^#myhostname" /etc/postfix/main.test-multi-comment | wc -l)
	do_postconf -# myhostname
	result=$(grep -E "^#myhostname" /etc/postfix/main.cf | wc -l)
	[ "$result" == "$COMMENT_COUNT" ]
}

@test "no sasl password duplications" {
	local RELAYHOST="demo"
	local RELAYHOST_USERNAME="foo"
	local RELAYHOST_PASSWORD="bar"

	postfix_setup_relayhost
	postfix_setup_relayhost

	result=$(grep -E "^demo" /etc/postfix/sasl_passwd | wc -l)
	[ "$result" == "1" ]
}