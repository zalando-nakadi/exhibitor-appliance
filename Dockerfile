FROM ubuntu:14.04

MAINTAINER Alexander Kukushkin <alexander.kukushkin@zalando.de>

ENV USER zookeeper
ENV HOME /opt/${USER}

ENV \
    ZOOKEEPER="http://www.apache.org/dist/zookeeper/zookeeper-3.4.6/zookeeper-3.4.6.tar.gz" \
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

ADD web.xml /opt/exhibitor/web.xml
ADD run.sh /opt/exhibitor/run.sh
ADD exhibitor.conf.tmpl /opt/exhibitor/exhibitor.conf.tmpl

RUN apt-get update
RUN apt-get install -y --force-yes wget apt-transport-https python
RUN wget -q https://www.scalyr.com/scalyr-repo/stable/latest/scalyr-agent-2.0.11.tar.gz
RUN tar -zxf scalyr-agent-2.0.11.tar.gz -C /tmp
RUN rm scalyr-agent-2.0.11.tar.gz
ENV PATH=/tmp/scalyr-agent-2.0.11/bin:$PATH
RUN chmod -R 777 /tmp/scalyr-agent-2.0.11/
ADD scalyr_startup.sh /tmp/scalyr_startup.sh
RUN chmod 777 /tmp/scalyr_startup.sh

WORKDIR ${HOME}
USER ${USER}

EXPOSE 2181 2888 3888 8181

CMD /tmp/scalyr_startup.sh && bash -ex /opt/exhibitor/run.sh
