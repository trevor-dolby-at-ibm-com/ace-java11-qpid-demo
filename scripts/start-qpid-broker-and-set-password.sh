#!/bin/bash

# Exit on error
set -e

export QPID_WORK=/tmp/qpid-work
cd /home/aceuser/qpid/*broker*/*/bin
export PATH=/opt/ibm/ace-12/common/java11/bin:$PATH
$PWD/qpid-server &

# Allow polling to work!
set +e

for i in `seq 1 60`
do
    password=`grep password /tmp/qpid-work/config.json 2>/dev/null | tr -d '"' | tr ':' '\n' | grep -v password`
    if [ "$password" == "" ]; then
	if [ $( expr $i % 10 ) == "0" ]; then
	     echo "Still waiting after" $( expr $i \* 5 ) "seconds . . ."
	fi
	sleep 2
    else
        echo "Qpid broker running at " `date`
	break
    fi
done

# Give qpid a chance to start fully
sleep 2

# Exit on error
set -e

echo "Setting password for JMS connection"
# This will fail if the password is blank
mqsisetdbparms -w /home/aceuser/ace-server -n jms::demoCF -u guest -p $password
