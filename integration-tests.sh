#!/usr/bin/env bash
set -e
cd integration-tests

run_test() {
    local exit_code
    echo
    echo
    echo "☆☆☆☆☆☆☆☆☆☆ $1 ☆☆☆☆☆☆☆☆☆☆"
    echo
    (
        cd "$1"
        set +e
        docker-compose up --build --abort-on-container-exit --exit-code-from tests
        exit_code="$?"

        docker-compose down -v
        if [[ "$exit_code" != 0 ]]; then
            exit "$exit_code"
        fi
        set -e
    )
}

if [[ $# -gt 0 ]]; then
    while [[ -n "$1" ]]; do
        run_test "$1"
        shift
    done
else
    # Disable xoauth2 integration tests as they an access and refresh token. And these expire
    # after a certain time, so we cannot rely on tests working all the time.
    for i in `find -maxdepth 1 -type d | grep -Ev "^./(xoauth2|tester)" | sort`; do
        i="$(basename "$i")"
        if [ "$i" == "." ] || [ "$i" == ".." ]; then
            continue
        fi
        run_test $i
    done
fi