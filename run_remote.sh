#!/bin/bash

ssh $1@$2 'cat | bash /dev/stdin' "$3" < sysmon.sh
