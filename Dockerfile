# Override for other variants
ARG BASE_IMAGE=ace-basic:12.0.10.0-ubuntu
FROM $BASE_IMAGE

ARG LICENSE

# docker build --build-arg LICENSE=accept --build-arg BASE_IMAGE=tdolby/experimental:ace-basic-12.0.10.0-ubuntu -t ace-java11-qpid-demo .
# docker build --build-arg LICENSE=accept --build-arg BASE_IMAGE=cp.icr.io/cp/appc/ace:12.0.10.0-r1 -t ace-java11-qpid-demo .
# docker run -e LICENSE=accept --rm -ti ace-java11-qpid-demo


COPY install-prereqs.sh /tmp/install-prereqs.sh
USER 0
RUN bash /tmp/install-prereqs.sh
# aceuser
USER 1001

COPY download-qpid.sh /tmp/download-qpid.sh
RUN mkdir /home/aceuser/qpid
WORKDIR /home/aceuser/qpid
RUN bash /tmp/download-qpid.sh

# Hacky way to get all the projects into the build container; ideally we would
# build everything outside the container build process, and just copy in the
# finished artifacts . . . 
WORKDIR /tmp/build
COPY . . 

RUN ls -l /tmp/
RUN ls -l /tmp/build


# Switch off the admin REST API for the server run, as we won't be deploying anything after start
RUN sed -i 's/#port: 7600/port: -1/g' /home/aceuser/ace-server/server.conf.yaml

RUN bash -c "export LICENSE=${LICENSE} ; . /opt/ibm/ace-12/server/bin/mqsiprofile ; \
    ibmint deploy --input-path /tmp/build --output-work-directory /home/aceuser/ace-server/ \
    && ibmint optimize server --work-dir /home/aceuser/ace-server"

# 2023-10-24 01:58:25.228930: BIP2230E: Error detected whilst processing a message in node 'PutFlow.JMS Output'.
# 2023-10-24 01:58:25.228966: BIP4367E: The method 'evaluate' in Java node 'JMS Output' has thrown the following exception: java.lang.UnsupportedClassVersionError: JVMCFRE199E bad major version 55.0 of class=org/apache/qpid/jms/jndi/JmsInitialContextFactory, the maximum supported major version is 52.0; offset=6.
# 2023-10-24 01:58:25.229000: BIP4395E: Java exception: 'java.lang.UnsupportedClassVersionError'; thrown from class name: 'java.lang.ClassLoader', method name: 'defineClassImpl', file: 'ClassLoader.java', line: '-2'
# 2023-10-24 01:58:25.229076: BIP4367E: The method 'defineClassImpl' in Java node 'unknown' has thrown the following exception: java.lang.UnsupportedClassVersionError: JVMCFRE199E bad major version 55.0 of class=org/apache/qpid/jms/jndi/JmsInitialContextFactory, the maximum supported major version is 52.0; offset=6

RUN bash -c "export LICENSE=${LICENSE} ; . /opt/ibm/ace-12/server/bin/mqsiprofile ; \
    ibmint specify jre --version 11 --work-dir /home/aceuser/ace-server"

COPY apache-qpid-jndi.properties /tmp
COPY start-qpid-broker-and-set-password.sh /tmp/

# Set entrypoint to run the server
ENTRYPOINT ["bash", "-c", ". /opt/ibm/ace-12/server/bin/mqsiprofile ; \
  /tmp/start-qpid-broker-and-set-password.sh && \
  IntegrationServer -w /home/aceuser/ace-server"]
