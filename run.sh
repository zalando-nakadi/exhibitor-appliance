#/bin/bash -e

if [[ "x$USE_HOSTNAME" == "xyes" ]]; then
    HOSTNAME=$(curl --connect-timeout 5 http://169.254.169.254/latest/meta-data/hostname || echo $(hostname))
else
    HOSTNAME=$(curl --connect-timeout 5 http://169.254.169.254/latest/meta-data/local-ipv4 || echo $(hostname))
fi

AVAILABILITY_ZONE=$(curl --connect-timeout 5 http://169.254.169.254/latest/meta-data/placement/availability-zone || echo "")

# creates snapshot and transactions directory if not present. Some
# users mount empty formatted volumes for data storage, so the
# directories need to be created on startup.
if [[ "x$TRANSACTIONS_DIR" == "x" ]]; then
    TRANSACTIONS_DIR="/opt/zookeeper/transactions"
fi
mkdir -m 777 -p ${TRANSACTIONS_DIR}
if [[ "x$SNAPSHOTS_DIR" == "x" ]]; then
   SNAPSHOTS_DIR="/opt/zookeeper/snapshots"
fi
mkdir -m 777 -p ${SNAPSHOTS_DIR}

# Generates the default exhibitor config and launches exhibitor
cat /opt/exhibitor/exhibitor.conf.tmpl > exhibitor.conf
echo "backup-extra=throttle\=&bucket-name\=${S3_BUCKET}&key-prefix\=${S3_PREFIX}&max-retries\=4&retry-sleep-ms\=30000" >> exhibitor.conf
echo "zookeeper-data-directory=${SNAPSHOTS_DIR}" >> exhibitor.conf
echo "zookeeper-log-directory=${TRANSACTIONS_DIR}" >> exhibitor.conf
echo "log-index-directory=${TRANSACTIONS_DIR}" >> exhibitor.conf

if [[ -n ${ZK_PASSWORD} ]]; then
    SECURITY="--security /opt/exhibitor/web.xml --realm Zookeeper:realm --remoteauth basic:zk"
    echo "zk: ${ZK_PASSWORD},zk" > realm
fi

if [[ $AVAILABILITY_ZONE == '' ]]; then
    echo "local environment, starting without S3 backup"
    CONFIG_TYPE="file"
else
    if [[ "x$AWS_REGION" == "x" ]]; then
        AWS_REGION=${AVAILABILITY_ZONE:0:${#AVAILABILITY_ZONE} - 1}
    fi
    CONFIG_TYPE="s3  --s3config ${S3_BUCKET}:${S3_PREFIX} --s3region ${AWS_REGION} --s3backup true"
fi

# send zookeeper log to stdout

exec 2>&1

java -javaagent:/opt/jolokia-jvm-${JOLOKIA_VERSION}-agent.jar=port=8778,host=0.0.0.0 -jar /opt/exhibitor/exhibitor.jar \
  --port 8181 --defaultconfig exhibitor.conf \
  --configtype $CONFIG_TYPE \
  --hostname ${HOSTNAME} \
  ${SECURITY}
