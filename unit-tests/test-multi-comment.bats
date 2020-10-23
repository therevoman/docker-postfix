#!/usr/bin/env bats

load /code/scripts/common.sh
load /code/scripts/common-run.sh

@test "make sure #myhostname appears four times in main.cf (default)" {
	result=$(grep -E "^#myhostname" /etc/postfix/main.cf | wc -l)
	[ "$result" == "4" ]
}

@test "make sure commenting out #myhostname does not incrase count" {
	do_postconf -# myhostname
	result=$(grep -E "^#myhostname" /etc/postfix/main.cf | wc -l)
	[ "$result" == "4" ]
}

@test "make sure adding myhostname does not incrase count" {
	do_postconf -e myhostname=localhost
	result=$(grep -E "^#myhostname" /etc/postfix/main.cf | wc -l)
	[ "$result" == "4" ]
}

@test "make sure adding myhostname is added only once" {
	do_postconf -e myhostname=localhost
	result=$(grep -E "^myhostname" /etc/postfix/main.cf | wc -l)
	[ "$result" == "1" ]
}

@test "make sure deleting myhostname does not incrase count" {
	do_postconf -# myhostname
	result=$(grep -E "^#myhostname" /etc/postfix/main.cf | wc -l)
	[ "$result" == "4" ]
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