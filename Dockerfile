# The contents of this file are subject to the license and copyright
# detailed in the LICENSE and NOTICE files at the root of the source

FROM maven:3.5.0-jdk-8

# Environment variables
ARG TOMCAT_MAJOR
ARG TOMCAT_VERSION

ENV \
    TOMCAT_MAJOR=${TOMCAT_MAJOR:-8} \
    TOMCAT_VERSION=${TOMCAT_VERSION:-8.5.20}

ENV TOMCAT_TGZ_URL=https://www.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz \
    CATALINA_HOME=/usr/local/tomcat

ENV PATH=$CATALINA_HOME/bin:$PATH

WORKDIR ${CATALINA_HOME}

RUN curl -fSL "${TOMCAT_TGZ_URL}" | tar -xz --strip-components=1

# Set default user tomcat:password
COPY tomcat-users.xml ${CATALINA_HOME}/conf/tomcat-users.xml

# Build info
RUN echo "Debian GNU/Linux 8 (jessie) image. (`uname -rsv`)" >> /root/.built && \
echo "- with `java -version 2>&1 | awk 'NR == 2'`" >> /root/.built && \
echo "- with Tomcat $TOMCAT_VERSION"  >> /root/.built

RUN apt-get update && apt-get install -y ant git postgresql-client postgresql-contrib

# Install root filesystem
ADD ./fs /

ENV DSPACE_HOME=/dspace

ENV CRIS_URL=https://github.com/4Science/DSpace \
    PATH=$CATALINA_HOME/bin:${DSPACE_HOME}/bin:$PATH \
    DSPACE_CFG=/dspace/config/dspace.cfg

ARG CRIS_VERSION
ENV CRIS_VERSION=${CRIS_VERSION:-dspace-cris-5.7.0}

WORKDIR ${DSPACE_HOME}-src
RUN echo "Get DSpace-CRIS version: ${CRIS_VERSION}" \
    && git clone --depth 1 --branch ${CRIS_VERSION} ${CRIS_URL} .

#RUN cp dspace/config/local.cfg.EXAMPLE dspace/config/local.cfg


ENV MAVEN_OPTS: "-Dmaven.repo.local=.m2/repository -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=WARN -Dorg.slf4j.simpleLogger.showDateTime=true -Djava.awt.headless=true"
ENV MAVEN_CLI_OPTS: "--batch-mode --errors --fail-at-end --show-version -DinstallAtEnd=true -DdeployAtEnd=true"

RUN mvn $MAVEN_CLI_OPTS package > /dev/null

WORKDIR ${DSPACE_HOME}-src/dspace/target/dspace-installer
RUN ant init_installation init_configs install_code copy_webapps \
    && rm -fr "$CATALINA_HOME/webapps" && mv -f ${DSPACE_HOME}/webapps "$CATALINA_HOME" \
    && sed -i s/CONFIDENTIAL/NONE/ $CATALINA_HOME/webapps/rest/WEB-INF/web.xml

WORKDIR ${DSPACE_HOME}

#RUN useradd -m dspace \
#    && chown -R dspace ${DSPACE_HOME}
#USER dspace

# COPY start scripts
COPY ./fs /

EXPOSE 8080
ENTRYPOINT ["wait-for-postgres.sh", "postgres"]
CMD ["start-dspace"]


# Add metadata
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL org.label-schema.schema-version="1.0" \
      org.label-schema.vendor="DSpace-CRIS Community" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.version=$VERSION \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/4science/dspace-docker" \
      org.label-schema.name="dspace-docker"
