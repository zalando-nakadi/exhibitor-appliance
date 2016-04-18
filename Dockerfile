FROM ubuntu:14.04

MAINTAINER Alexander Kukushkin <alexander.kukushkin@zalando.de>

ENV USER zookeeper
ENV HOME /opt/${USER}
ENV ZOOKEEPER_VERSION="3.4.6"

ENV \
    ZOOKEEPER="http://www.apache.org/dist/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz" \
    EXHIBITOR_POM="https://raw.githubusercontent.com/Netflix/exhibitor/master/exhibitor-standalone/src/main/resources/buildscripts/standalone/maven/pom.xml" \
    BUILD_DEPS="maven openjdk-7-jdk+"

RUN \
    # Install dependencies
    apt-get update \
    && apt-get install -y --allow-unauthenticated --no-install-recommends $BUILD_DEPS curl \

    # Default DNS cache TTL is -1. DNS records, like, change, man.
    && grep '^networkaddress.cache.ttl=' /etc/java-7-openjdk/security/java.security || echo 'networkaddress.cache.ttl=60' >> /etc/java-7-openjdk/security/java.security \

    # Create home directory for zookeeper
    && useradd -d ${HOME} -k /etc/skel -s /bin/bash -m ${USER} \

    # Install ZK
    && curl -L $ZOOKEEPER | tar xz -C $HOME --strip=1 \

    && chmod 777 ${HOME} ${HOME}/conf && mkdir -m 777 ${HOME}/transactions \

    # Install Exhibitor
    && mkdir -p /opt/exhibitor \
    && curl -Lo /opt/exhibitor/pom.xml $EXHIBITOR_POM \
    && mvn -f /opt/exhibitor/pom.xml package \
    && ln -s /opt/exhibitor/target/exhibitor*jar /opt/exhibitor/exhibitor.jar \

    # Remove build-time dependencies
    && apt-get purge -y --auto-remove $BUILD_DEPS \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh web.xml exhibitor.conf.tmpl /opt/exhibitor/
COPY scm-source.json /scm-source.json

WORKDIR ${HOME}
USER ${USER}

EXPOSE 2181 2888 3888 8181

ENTRYPOINT ["bash", "-ex", "/opt/exhibitor/run.sh"]
