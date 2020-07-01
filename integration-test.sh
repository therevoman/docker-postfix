#!/bin/sh
set -e
cd integration-tests
for i in `find -maxdepth 1 -type d`; do
    i="$(basename "$i")"
    if [ "$i" == "tester" ] || [ "$i" == "." ] || [ "$i" == ".." ]; then
        continue
    fi
    (
        echo "$i"
        cd "$i"
        docker-compose up --build --abort-on-container-exit --exit-code-from tests
    )
done