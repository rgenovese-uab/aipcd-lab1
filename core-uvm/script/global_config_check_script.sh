#!/bin/bash

git config --global --get-regexp insteadOf > file_list
cat file_list
grep -E "insteadof" file_list &> /dev/null; VAR=$(echo $?); echo $VAR
if [ $VAR -eq 0 ]; then
   while read file_list; do
       git config --global --unset ${file_list}
   done < file_list
else
   echo "no url exists in global config file"
fi
rm file_list
