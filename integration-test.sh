#!/bin/sh
cd integration-tests
docker-compose up --build --abort-on-container-exit --exit-code-from tests