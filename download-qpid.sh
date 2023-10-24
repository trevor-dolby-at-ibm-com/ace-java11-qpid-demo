#!/bin/bash

export DOWNLOAD_CONNECTION_COUNT=5

curl=0
which aria2c > /dev/null 2>&1
if [ "$?" == "0" ]; then
    # Found aria2
    curl=0
else
    # Use curl
    curl=1
fi

# Fix for ace-minimal for java11 only
unset LD_LIBRARY_PATH

# Exit on error
set -e

export QPID_BROKER_DOWNLOAD_URL=https://dlcdn.apache.org/qpid/broker-j/9.1.0/binaries/apache-qpid-broker-j-9.1.0-bin.tar.gz
if [ "$curl" == "0" ]; then
    aria2c -s ${DOWNLOAD_CONNECTION_COUNT} -j ${DOWNLOAD_CONNECTION_COUNT} -x ${DOWNLOAD_CONNECTION_COUNT} "${QPID_BROKER_DOWNLOAD_URL}"
    tar -xvf *broker*tar.gz
else
    curl "${QPID_BROKER_DOWNLOAD_URL}" | tar -xzvf -
fi

# This would work with Java8 but is quite old (and the URL may not be around for much longer)
# export QPID_JMS_DOWNLOAD_URL=https://archive.apache.org/dist/qpid/jms/0.61.0/apache-qpid-jms-0.61.0-bin.tar.gz

# This one requires Java11 or later
export QPID_JMS_DOWNLOAD_URL=https://dlcdn.apache.org/qpid/jms/1.10.0/apache-qpid-jms-1.10.0-bin.tar.gz

if [ "$curl" == "0" ]; then
    aria2c -s ${DOWNLOAD_CONNECTION_COUNT} -j ${DOWNLOAD_CONNECTION_COUNT} -x ${DOWNLOAD_CONNECTION_COUNT} "${QPID_JMS_DOWNLOAD_URL}"
    tar -xvf *jms*tar.gz
else
    curl "${QPID_JMS_DOWNLOAD_URL}" | tar -xzvf -
fi

echo "Copying JMS JARs to ACE shared-classes directory"
mkdir /home/aceuser/ace-server/shared-classes
cp *jms*/lib/*.jar /home/aceuser/ace-server/shared-classes/
