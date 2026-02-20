#!/usr/bin/env bash
output=$(./hello.sh)
if [ "$output" = "hello" ]; then
  echo "PASS: hello.sh prints hello"
  exit 0
else
  echo "FAIL: expected 'hello', got '$output'"
  exit 1
fi
