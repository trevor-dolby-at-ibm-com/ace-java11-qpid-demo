#!/bin/bash
#
# This script automates the building and testing of the application.
#
# Copyright (c) 2023 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)
#

# In case this hasn't been done already
. /opt/ibm/ace-12/server/bin/mqsiprofile > /dev/null 2>&1

# Exit on any failure
set -e

# This repo is intended to show how to work with Java11 rather than
# as an example of how to build a perfect pipeline, so we run the
# tests from the main work directory and then delete the tests
# afterwards. Normally the tests would be run in their own work
# directory to avoid any accidental shipping of test data or code . . .

# Build everything; we can do this in this case because we want to include the unit
# tests, but production builds should specify the projects.
ibmint deploy --input-path /tmp/build --output-work-directory /home/aceuser/ace-server

# Switch off the webUI port as we won't need it in a container
sed -i 's/#port: 7600/port: -1/g' /home/aceuser/ace-server/server.conf.yaml

# ibmint optimize server new for v12.0.4 - speed up test runs and container start
ibmint optimize server --work-directory /home/aceuser/ace-server

# Run the server to run the unit tests - note that this should not require Java11
# as it will only run unit tests rather than actually using JMS.
IntegrationServer -w /home/aceuser/ace-server --test-project JMSSender_UnitTest 

# Remove the test project - see comment above
rm -rf /home/aceuser/ace-server/run/JMSSender_UnitTest
