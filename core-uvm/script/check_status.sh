#!/bin/bash

grep -E "FAILURE|MISMATCH|TIMEOUT|ROB_FAULT|None|null|PC MISMATCH|RESULT MISMATCH|REPORT MISSING" result.txt &> /dev/null; VAR=$(echo $?)
echo $VAR
if [ $VAR -eq 0 ]; then
  echo "Tests failed" && exit 1
else
  echo "All tests are passing"
fi

