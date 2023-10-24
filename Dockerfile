# Override for other variants
ARG BASE_IMAGE=cp.icr.io/cp/appc/ace:12.0.10.0-r1
FROM $BASE_IMAGE

ARG LICENSE

# BASE_IMAGE can be set to the IBM-provided ACE container (as above), or to either
# ace-basic:12.0.10.0-ubuntu or ace-minimal:12.0.10.0-alpine-java11 from ace-docker
#
# docker build --build-arg LICENSE=accept --build-arg BASE_IMAGE=cp.icr.io/cp/appc/ace:12.0.10.0-r1 -t ace-java11-qpid-demo .
# docker run -e LICENSE=accept --rm -ti ace-java11-qpid-demo


# This section is needed to avoid issues with ubi8-minimal not having tar . . .
COPY scripts/install-prereqs.sh /tmp/install-prereqs.sh
USER 0
RUN bash /tmp/install-prereqs.sh
# aceuser
USER 1001

COPY scripts/download-qpid.sh /tmp/download-qpid.sh
RUN mkdir /home/aceuser/qpid
WORKDIR /home/aceuser/qpid
RUN bash /tmp/download-qpid.sh

# Hacky way to get all the projects into the build container without naming them . . .
WORKDIR /tmp/build
COPY . .
#
# Build the application and run the unit tests; this does not requires Java11
#
RUN bash -c "export LICENSE=${LICENSE} && /tmp/build/scripts/build-and-ut.sh"

# Switch the server to use Java11; comment out the RUN lines to see errors like the
# following due to running Java8:
#
# 2023-10-24 01:58:25.228966: BIP4367E: The method 'evaluate' in Java node 'JMS Output' has thrown the following exception: java.lang.UnsupportedClassVersionError: JVMCFRE199E bad major version 55.0 of class=org/apache/qpid/jms/jndi/JmsInitialContextFactory, the maximum supported major version is 52.0; offset=6.
# 2023-10-24 01:58:25.229000: BIP4395E: Java exception: 'java.lang.UnsupportedClassVersionError'; thrown from class name: 'java.lang.ClassLoader', method name: 'defineClassImpl', file: 'ClassLoader.java', line: '-2'
#
RUN bash -c "export LICENSE=${LICENSE} ; . /opt/ibm/ace-12/server/bin/mqsiprofile ; \
    ibmint specify jre --version 11 --work-dir /home/aceuser/ace-server"


# Qpid setup files
COPY apache-qpid-jndi.properties /tmp
COPY scripts/start-qpid-broker-and-set-password.sh /tmp/

# Set entrypoint to start the Qpid broker (plus calling mqsisetdbparms to
# set the connection password) and run the server
ENTRYPOINT ["bash", "-c", ". /opt/ibm/ace-12/server/bin/mqsiprofile ; \
  /tmp/start-qpid-broker-and-set-password.sh && \
  IntegrationServer -w /home/aceuser/ace-server"]
