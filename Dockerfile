FROM ubuntu:14.04

MAINTAINER Alexander Kukushkin <alexander.kukushkin@zalando.de>

ENV USER zookeeper
ENV HOME /opt/${USER}

# Create home directory for zookeeper
RUN useradd -d ${HOME} -k /etc/skel -s /bin/bash -m ${USER}

ENV ZOOKEEPER_VERSION="3.4.10"

ENV \
    ZOOKEEPER="http://www.apache.org/dist/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz" \
    EXHIBITOR_POM="https://raw.githubusercontent.com/soabase/exhibitor/master/exhibitor-standalone/src/main/resources/buildscripts/standalone/maven/pom.xml" \
    BUILD_DEPS="maven openjdk-7-jdk+"

RUN export DEBIAN_FRONTEND=noninteractive \
    # Install dependencies
    && echo 'APT::Install-Recommends "0";' > /etc/apt/apt.conf.d/01norecommend \
    && echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/01norecommend \

    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --allow-unauthenticated $BUILD_DEPS curl \

    # Default DNS cache TTL is -1. DNS records, like, change, man.
    && grep '^networkaddress.cache.ttl=' /etc/java-7-openjdk/security/java.security || echo 'networkaddress.cache.ttl=60' >> /etc/java-7-openjdk/security/java.security \

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
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /root/.m2

RUN ln -sf /dev/stdout /opt/zookeeper/zookeeper.out
COPY run.sh web.xml exhibitor.conf.tmpl /opt/exhibitor/
COPY scm-source.json /scm-source.json
RUN ln -sf /dev/stdout /opt/zookeeper/zookeeper.out
WORKDIR ${HOME}
USER ${USER}

EXPOSE 2181 2888 3888 8181

ENTRYPOINT ["bash", "-ex", "/opt/exhibitor/run.sh"]
